import { json } from "@sveltejs/kit";
import lighthouse from "@lighthouse-web3/sdk";

const LIGHTHOUSE_API_KEY = "39e449c2.91cdb383ba874acea44aeff3ca11875a";

export async function POST({ request }) {
    try {
        const formData = await request.formData();
        const file = formData.get("file");

        if (!file) {
            return json({ error: "No file received" }, { status: 400 });
        }

        // Convert to Buffer (required by Lighthouse SDK)
        const arrayBuffer = await file.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);

        const uploadResponse = await lighthouse.uploadBuffer(
            buffer,
            LIGHTHOUSE_API_KEY,
            file.name
        );

        return json({
            cid: uploadResponse.data.Hash
        });

    } catch (err) {
        console.error(err);

        return json(
            {
                error: "Upload failed",
                details: err.message
            },
            { status: 500 }
        );
    }
}
