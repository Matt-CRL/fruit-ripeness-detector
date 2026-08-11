import { createClient } from "npm:@supabase/supabase-js@2";

const bucketName = "scan-images";

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

async function listAccountObjects(
  admin: ReturnType<typeof createClient>,
  userId: string,
) {
  const keys: string[] = [];
  let folderOffset = 0;

  while (true) {
    const { data: folders, error: folderError } = await admin.storage
      .from(bucketName)
      .list(userId, { limit: 1000, offset: folderOffset, sortBy: { column: "name", order: "asc" } });
    if (folderError) throw folderError;
    if (!folders || folders.length === 0) break;

    for (const folder of folders) {
      const scanPrefix = `${userId}/${folder.name}`;
      let fileOffset = 0;
      while (true) {
        const { data: files, error: fileError } = await admin.storage
          .from(bucketName)
          .list(scanPrefix, { limit: 1000, offset: fileOffset });
        if (fileError) throw fileError;
        if (!files || files.length === 0) break;
        keys.push(...files.map((file) => `${scanPrefix}/${file.name}`));
        if (files.length < 1000) break;
        fileOffset += files.length;
      }
    }

    if (folders.length < 1000) break;
    folderOffset += folders.length;
  }

  return keys;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { code: "method_not_allowed" });
  }

  const authorization = request.headers.get("authorization");
  const projectUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const secretKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");

  if (!authorization || !projectUrl || !publishableKey || !secretKey) {
    return jsonResponse(401, { code: "not_authenticated" });
  }

  const userClient = createClient(projectUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse(401, { code: "not_authenticated" });
  }

  const admin = createClient(projectUrl, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const objectKeys = await listAccountObjects(admin, userData.user.id);
    for (let index = 0; index < objectKeys.length; index += 1000) {
      const { error } = await admin.storage
        .from(bucketName)
        .remove(objectKeys.slice(index, index + 1000));
      if (error) throw error;
    }

    const { error: deletionError } = await admin.auth.admin.deleteUser(
      userData.user.id,
      false,
    );
    if (deletionError) throw deletionError;

    return jsonResponse(200, { deleted: true });
  } catch (_) {
    return jsonResponse(503, { code: "account_deletion_failed" });
  }
});
