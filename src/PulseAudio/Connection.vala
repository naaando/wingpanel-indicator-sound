public class Sound.PulseAudioConnection : GLib.Object {
    public signal void ready ();
    public PulseAudio.Context context { get; private set; }
    private PulseAudio.GLibMainLoop loop;
    private bool is_ready = false;
    private uint reconnect_timer_id = 0U;

    construct {
        loop = new PulseAudio.GLibMainLoop ();
        reconnect_to_pulse.begin ();
    }

    public void test () {
        debug (context.get_state ().to_string ());
    }

    public void subscribe (PulseAudio.Context.SubscriptionMask mask, PulseAudio.Context.SubscribeCb callback) {
        context.set_subscribe_callback (callback);
        if (context.get_state () == PulseAudio.Context.State.READY) {
            context.subscribe (mask);
        }
    }

    /*
     * Private methods to connect to the PulseAudio async interface
     */

    private bool reconnect_timeout () {
        reconnect_timer_id = 0U;
        reconnect_to_pulse.begin ();
        return false; // G_SOURCE_REMOVE
    }

    private async void reconnect_to_pulse () {
        if (is_ready) {
            context.disconnect ();
            context = null;
            is_ready = false;
        }

        var props = new PulseAudio.Proplist ();
        props.sets (PulseAudio.Proplist.PROP_APPLICATION_ID, "io.elementary.desktop.wingpanel.sound");
        context = new PulseAudio.Context (loop.get_api (), null, props);
        context.set_state_callback (context_state_callback);

        if (context.connect (null, PulseAudio.Context.Flags.NOFAIL, null) < 0) {
            warning ("pa_context_connect() failed: %s\n", PulseAudio.strerror (context.errno ()));
        }
    }

    private void context_state_callback (PulseAudio.Context c) {
        debug (c.get_state ().to_string ());
        switch (c.get_state ()) {
            case PulseAudio.Context.State.READY:
                // c.set_subscribe_callback (subscribe_callback);
                // c.subscribe (PulseAudio.Context.SubscriptionMask.SERVER |
                //         PulseAudio.Context.SubscriptionMask.SINK |
                //         PulseAudio.Context.SubscriptionMask.SOURCE |
                //         PulseAudio.Context.SubscriptionMask.SINK_INPUT |
                //         PulseAudio.Context.SubscriptionMask.SOURCE_OUTPUT);
                // context.get_server_info (server_info_callback);
                is_ready = true;
                ready ();
                break;

            case PulseAudio.Context.State.FAILED:
            case PulseAudio.Context.State.TERMINATED:
                if (reconnect_timer_id == 0U)
                    reconnect_timer_id = Timeout.add_seconds (2, reconnect_timeout);
                break;

            default:
                is_ready = false;
                break;
        }
    }
}
