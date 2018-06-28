
public class Sound.OutputControl : Object {
    PulseAudioConnection con;
    public Gee.HashMap<uint32, Device> output_devices;
    public Device default_output { get; private set; }
    public signal void new_device (Device dev);

    construct {
        con = new Sound.PulseAudioConnection ();
        output_devices = new Gee.HashMap<uint32, Device> ();

        con.ready.connect (() => {
            output_devices.clear ();

            con.context.get_sink_info_list ((context, sink, eol) => {
                if (sink == null) {
                    return;
                }

                add_sink (new Device.from_sink_info (sink));
            });

            con.subscribe (PulseAudio.Context.SubscriptionMask.SERVER | PulseAudio.Context.SubscriptionMask.SINK | PulseAudio.Context.SubscriptionMask.SINK_INPUT, subscribe_callback);
        });
    }

    public void set_default_device (Device dev) {
        if (!dev.input) {
            con.context.set_default_sink (dev.name, null);
        }
    }

    // public Device get_default_device () {
    //     context.set_default_sink (device.name, null);
    // }

    private void subscribe_callback (PulseAudio.Context context, PulseAudio.Context.SubscriptionEventType t, uint32 index) {
        var source_type = t & PulseAudio.Context.SubscriptionEventType.FACILITY_MASK;

        switch (source_type) {
            case PulseAudio.Context.SubscriptionEventType.SERVER:
                context.get_server_info ((context, server_info) => {
                    if (server_info == null)
                        return;

                    foreach (var device in output_devices) {
                        debug (server_info.default_sink_name);
                        if (device.name == server_info.default_sink_name) {
                            debug (device.name);
                            default_output = device;
                        }
                    }
                });
                break;
            case PulseAudio.Context.SubscriptionEventType.SINK:
            case PulseAudio.Context.SubscriptionEventType.SINK_INPUT:
                var event_type = t & PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                switch (event_type) {
                    case PulseAudio.Context.SubscriptionEventType.NEW:
                        context.get_sink_info_by_index (index, new_sink);
                        break;

                    case PulseAudio.Context.SubscriptionEventType.CHANGE:
                        // context.get_sink_info_by_index (index, change_sink);
                        break;

                    case PulseAudio.Context.SubscriptionEventType.REMOVE:
                        var device = output_devices.get (index);
                        if (device != null) {
                            device.removed ();
                            output_devices.unset (index);
                        }

                        break;
                }
            break;
        }
    }

    private void new_sink (PulseAudio.Context c, PulseAudio.SinkInfo? i, int eol) {
        if (i == null) {
            return;
        }

        add_sink (new Device.from_sink_info (i));
    }

    private void add_sink (Device device) {
        debug ("Adding device "+device.display_name);
        if (output_devices.has_key (device.index)) {
            debug ("Device index has already taken, overwriting");
        }

        output_devices.set (device.index, device);
        if (device.is_default) {
            default_output = device;
        }

        new_device (device);
    }
}
