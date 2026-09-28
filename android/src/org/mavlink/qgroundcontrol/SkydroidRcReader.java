package org.mavlink.qgroundcontrol;

import android.content.Context;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.SystemClock;
import android.util.Log;

import com.skydroid.rcsdk.KeyManager;
import com.skydroid.rcsdk.RCSDKManager;
import com.skydroid.rcsdk.SDKManagerCallBack;
import com.skydroid.rcsdk.common.callback.CompletionCallbackWith;
import com.skydroid.rcsdk.common.error.SkyException;
import com.skydroid.rcsdk.key.RemoteControllerKey;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * Reads the Skydroid remote controller's own channel values through Skydroid's RCSDK,
 * so a Skydroid pod can follow the sticks when no flight controller is reporting
 * RC_CHANNELS.
 *
 * Read only. The one request made against the controller is a GET of KeyChannels:
 * nothing here sets, pairs, retunes or otherwise changes the controller or its link.
 *
 * All state lives on one handler thread. SDK callbacks arrive on the SDK's own
 * threads and are posted across before they touch anything.
 */
public final class SkydroidRcReader {
    private static final String TAG = SkydroidRcReader.class.getSimpleName();

    // Reported to native code; keep in step with SkydroidRcInput::State.
    private static final int STATE_STOPPED    = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED  = 2;
    private static final int STATE_FAILED     = 3;

    // These controllers cannot push stick values; each one has to be asked for, and
    // Skydroid asks for no more than one request per 100 ms.
    private static final long POLL_INTERVAL_MS = 100;
    // A request that is never answered must not stall polling for good.
    private static final long REQUEST_TIMEOUT_MS = 500;
    // The connection fails while another app holds the SDK's port (the Skydroid
    // assistant, typically). Retrying means closing that app is all it takes.
    private static final long RETRY_INTERVAL_MS = 5000;
    // How long shutdown waits for the SDK to hand its port back.
    private static final long STOP_WAIT_MS = 1000;

    private static native void nativeChannels(int[] channels);
    private static native void nativeState(int state, String message);

    private static Handler handler;
    private static Context appContext;
    private static boolean sdkInitialised;
    private static boolean wanted;
    private static boolean connected;
    private static long    requestSentAt; // 0 while no request is in flight

    private SkydroidRcReader() {}

    /** Starts reading. Safe to call repeatedly. */
    public static synchronized void start(final Context context) {
        if (handler == null) {
            final HandlerThread thread = new HandlerThread("SkydroidRcReader");
            thread.start();
            handler = new Handler(thread.getLooper());
        }
        if ((appContext == null) && (context != null)) {
            appContext = context.getApplicationContext();
        }
        handler.post(() -> {
            if (wanted) {
                return;
            }
            wanted = true;
            connect();
        });
    }

    /**
     * Stops reading and gives the SDK's port back, so the Skydroid assistant and other
     * apps can use it. Waits briefly for that to happen, since this is also what runs
     * when the app shuts down.
     */
    public static synchronized void stop() {
        if (handler == null) {
            return;
        }
        final CountDownLatch done = new CountDownLatch(1);
        handler.post(() -> {
            try {
                if (wanted) {
                    wanted = false;
                    handler.removeCallbacks(poll);
                    handler.removeCallbacks(retry);
                    release();
                    report(STATE_STOPPED, "");
                }
            } finally {
                done.countDown();
            }
        });
        try {
            if (!done.await(STOP_WAIT_MS, TimeUnit.MILLISECONDS)) {
                Log.w(TAG, "Timed out waiting for the remote controller connection to close");
            }
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static void connect() {
        if (!wanted) {
            return;
        }
        if (appContext == null) {
            fail("no application context");
            return;
        }
        try {
            if (!sdkInitialised) {
                RCSDKManager.INSTANCE.initSDK(appContext, sdkCallback);
                sdkInitialised = true;
            }
            report(STATE_CONNECTING, "");
            RCSDKManager.INSTANCE.connectToRC();
        } catch (final Throwable t) {
            // UnsatisfiedLinkError and friends on hardware the SDK does not support.
            fail(t.toString());
        }
    }

    private static void release() {
        connected = false;
        requestSentAt = 0;
        if (!sdkInitialised) {
            return;
        }
        try {
            RCSDKManager.INSTANCE.disconnectRC();
        } catch (final Throwable t) {
            Log.w(TAG, "disconnectRC failed", t);
        }
    }

    private static void fail(final String message) {
        Log.w(TAG, "Remote controller unavailable: " + message);
        release();
        report(STATE_FAILED, message);
        if (wanted) {
            handler.removeCallbacks(retry);
            handler.postDelayed(retry, RETRY_INTERVAL_MS);
        }
    }

    private static final Runnable retry = SkydroidRcReader::connect;

    private static final Runnable poll = new Runnable() {
        @Override
        public void run() {
            if (!wanted || !connected) {
                return;
            }
            final long now = SystemClock.uptimeMillis();
            if ((requestSentAt == 0) || ((now - requestSentAt) > REQUEST_TIMEOUT_MS)) {
                requestSentAt = now;
                try {
                    KeyManager.INSTANCE.get(RemoteControllerKey.INSTANCE.getKeyChannels(), channelsCallback);
                } catch (final Throwable t) {
                    requestSentAt = 0;
                    Log.w(TAG, "KeyChannels request failed", t);
                }
            }
            handler.postDelayed(this, POLL_INTERVAL_MS);
        }
    };

    private static final CompletionCallbackWith<int[]> channelsCallback = new CompletionCallbackWith<int[]>() {
        @Override
        public void onSuccess(final int[] channels) {
            handler.post(() -> {
                requestSentAt = 0;
                if (wanted && connected && (channels != null)) {
                    deliverChannels(channels);
                }
            });
        }

        @Override
        public void onFailure(final SkyException e) {
            handler.post(() -> requestSentAt = 0);
        }
    };

    private static final SDKManagerCallBack sdkCallback = new SDKManagerCallBack() {
        @Override
        public void onRcConnected() {
            handler.post(() -> {
                if (!wanted) {
                    release();
                    return;
                }
                connected = true;
                requestSentAt = 0;
                report(STATE_CONNECTED, "");
                handler.removeCallbacks(poll);
                handler.post(poll);
            });
        }

        @Override
        public void onRcConnectFail(final SkyException e) {
            handler.post(() -> {
                if (wanted) {
                    fail((e != null) ? e.toString() : "connection failed");
                }
            });
        }

        @Override
        public void onRcDisconnect() {
            handler.post(() -> {
                if (wanted) {
                    fail("disconnected");
                }
            });
        }
    };

    private static void deliverChannels(final int[] channels) {
        try {
            nativeChannels(channels);
        } catch (final UnsatisfiedLinkError e) {
            Log.w(TAG, "nativeChannels is not registered", e);
        }
    }

    private static void report(final int state, final String message) {
        try {
            nativeState(state, message);
        } catch (final UnsatisfiedLinkError e) {
            Log.w(TAG, "nativeState is not registered", e);
        }
    }
}
