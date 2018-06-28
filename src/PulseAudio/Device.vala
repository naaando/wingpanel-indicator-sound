// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2018 elementary LLC. (https://elementary.io)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

// This is a read-only class, set the properties via PulseAudioManager.
public class Sound.Device : GLib.Object {
    public class Port {
        public string name;
        public string description;
        public uint32 priority;
    }

    public signal void removed ();

    public bool input { get; set; default=true; }
    public uint32 index { get; construct; default=0U; }
    public string name { get; set; }
    public string display_name { get; set; }
    public string form_factor { get; set; }
    public bool is_default { get; set; default=false; }
    public bool is_muted { get; set; default=false; }
    public PulseAudio.CVolume cvolume { get; set; }
    public double volume { get; set; default=0; }
    public float balance { get; set; default=0; }
    public PulseAudio.ChannelMap channel_map { get; set; }
    public Gee.LinkedList<PulseAudio.Operation> volume_operations;
    public Gee.ArrayList<Port> ports { get; set; }
    public Port? default_port { get; set; default=null; }

    public Device (uint32 index) {
        Object (index: index);
    }

    public Device.from_sink_info (PulseAudio.SinkInfo info) {
        Object (index: info.index);
        input = false;
        name = info.name;
        display_name = info.description;
        is_muted = (info.mute != 0);
        cvolume = info.volume;
        channel_map = info.channel_map;
        balance = info.volume.get_balance (info.channel_map);
        volume_operations.foreach ((operation) => {
            if (operation.get_state () != PulseAudio.Operation.State.RUNNING) {
                volume_operations.remove (operation);
            }
            return GLib.Source.CONTINUE;
        });

        ports.clear ();
        default_port = null;

        // fix: Generating broken C code
        // for (uint32 idx = 0; idx < info.n_ports; idx++) {
        //     var new_port = new Device.Port ();
        //     new_port.name = info.ports[idx].name;
        //     new_port.description = info.ports[idx].description;
        //     new_port.priority = info.ports[idx].priority;
        //     ports.add (new_port);
        //
        //     if (info.ports[idx] == info.active_port) {
        //         default_port = new_port;
        //     }
        // }

        if (volume_operations.is_empty) {
            volume = volume_to_double (info.volume.max ());
        }

        var form_factor = info.proplist.gets (PulseAudio.Proplist.PROP_DEVICE_FORM_FACTOR);
        if (form_factor != null) {
            this.form_factor = form_factor;
        }
    }

    public Device.from_sorce_info (PulseAudio.SourceInfo info) {
        input = true;
        name = info.name;
        display_name = info.description;
        is_muted = (info.mute != 0);
        cvolume = info.volume;

        channel_map = info.channel_map;
        balance = info.volume.get_balance (info.channel_map);
        volume_operations.foreach ((operation) => {
            if (operation.get_state () != PulseAudio.Operation.State.RUNNING) {
                volume_operations.remove (operation);
            }

            return GLib.Source.CONTINUE;
        });

        ports.clear ();
        default_port = null;

        // for (int idx = 0; idx < info.n_ports; idx++) {
        //     var new_port = new Device.Port ();
        //     new_port.name = info.ports[idx].name;
        //     new_port.description = info.ports[idx].description;
        //     new_port.priority = info.ports[idx].priority;
        //     ports.add (new_port);
        //
        //     if (info.ports[idx] == info.active_port) {
        //         default_port = new_port;
        //     }
        // }

        if (volume_operations.is_empty) {
            volume = volume_to_double (info.volume.max ());
        }

        var form_factor = info.proplist.gets (PulseAudio.Proplist.PROP_DEVICE_FORM_FACTOR);
        if (form_factor != null) {
            this.form_factor = form_factor;
        }
    }

    construct {
        volume_operations = new Gee.LinkedList<PulseAudio.Operation> ();
        ports = new Gee.ArrayList<Port> ();
    }

    public string get_nice_form_factor () {
        switch (form_factor) {
            case "internal":
                return _("Built-in");
            case "speaker":
                return _("Speaker");
            case "handset":
                return _("Handset");
            case "tv":
                return _("TV");
            case "webcam":
                return _("Webcam");
            case "microphone":
                return _("Microphone");
            case "headset":
                return _("Headset");
            case "headphone":
                return _("Headphone");
            case "hands-free":
                return _("Hands-Free");
            case "car":
                return _("Car");
            case "hifi":
                return _("HiFi");
            case "computer":
                return _("Computer");
            case "portable":
                return _("Portable");
            default:
                return input? _("Input") : _("Output");
        }
    }

    private static double volume_to_double (PulseAudio.Volume vol) {
        double tmp = (double)(vol - PulseAudio.Volume.MUTED);
        return 100 * tmp / (double)(PulseAudio.Volume.NORM - PulseAudio.Volume.MUTED);
    }

    private static PulseAudio.Volume double_to_volume (double vol) {
        double tmp = (double)(PulseAudio.Volume.NORM - PulseAudio.Volume.MUTED) * vol/100;
        return (PulseAudio.Volume)tmp + PulseAudio.Volume.MUTED;
    }
}
