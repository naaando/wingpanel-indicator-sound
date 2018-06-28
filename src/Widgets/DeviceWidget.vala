
public class DeviceWidget : Gtk.Box {
    public Gee.HashMap<uint32, Gtk.RadioButton> devices;
    Gtk.Box list;
    Gtk.RadioButton last_button;

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        list = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        list.margin_start = list.margin_end = 6 + (list.margin_top = list.margin_end = 6);
        devices = new Gee.HashMap<uint32, Gtk.RadioButton> ();

        var revealer = new Gtk.Revealer ();
        revealer.add (list);

        var button = make_button ();

        button.button_release_event.connect ((e) => {
            revealer.reveal_child = !revealer.reveal_child;
            return Gdk.EVENT_STOP;
        });

        add (button);
        add (revealer);
    }

    public void on_server_change (Object obj, ParamSpec? spec = null) {
        var opc = (Sound.OutputControl) obj;
        var device = opc.default_output;
        if (device == null) {
            return;
        }

        if (devices.has_key (device.index)) {
            devices.get (device.index).set_active (true);
        }
    }

    public void add_device (Sound.OutputControl opc, Sound.Device device) {
        if (device == null) {
            return;
        }

        int max_len = 38;
        var rbtn = new Gtk.RadioButton.with_label_from_widget (last_button, device.display_name.length < max_len ? device.display_name : device.display_name[0:max_len]);
        last_button = rbtn;
        rbtn.toggled.connect (() => {
            opc.set_default_device (device);
        });

        devices.set (device.index, rbtn);
        list.add (rbtn);
    }

    private Gtk.Button make_button () {
        var button = new Gtk.ModelButton ();
        button.text = "Other devices...";

        return button;
    }
}
