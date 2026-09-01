package com.banyac.mijia.app.util;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.support.v4.content.FileProvider;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public final class ManualPdfOpener {
    private static final String URL_PREFIX = "file:///android_asset/help/manuals/";
    private static final String ASSET_PREFIX = "help/manuals/";

    private ManualPdfOpener() {
    }

    public static boolean open(Context context, String url) {
        if (context == null || url == null || !url.startsWith(URL_PREFIX)) {
            return false;
        }

        String fileName = url.substring(URL_PREFIX.length());
        if (!isSafePdfName(fileName)) {
            return false;
        }

        try {
            File directory = new File(context.getCacheDir(), "manuals");
            if (!directory.exists() && !directory.mkdirs()) {
                throw new IOException("Cannot create manual cache directory");
            }

            File output = new File(directory, fileName);
            copyAsset(context, ASSET_PREFIX + fileName, output);

            String authority = context.getPackageName() + ".fileprovider";
            Uri uri = FileProvider.getUriForFile(context, authority, output);
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(uri, "application/pdf");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            context.startActivity(intent);
        } catch (Exception error) {
            Toast.makeText(context, "No PDF viewer is available.", Toast.LENGTH_LONG).show();
        }
        return true;
    }

    private static boolean isSafePdfName(String fileName) {
        return fileName.length() > 4
                && fileName.endsWith(".pdf")
                && fileName.indexOf('/') < 0
                && fileName.indexOf('\\') < 0
                && fileName.indexOf("..") < 0;
    }

    private static void copyAsset(Context context, String assetName, File output) throws IOException {
        try (InputStream input = context.getAssets().open(assetName);
             FileOutputStream destination = new FileOutputStream(output, false)) {
            byte[] buffer = new byte[16 * 1024];
            int count;
            while ((count = input.read(buffer)) >= 0) {
                if (count > 0) {
                    destination.write(buffer, 0, count);
                }
            }
            destination.flush();
        }
    }
}
