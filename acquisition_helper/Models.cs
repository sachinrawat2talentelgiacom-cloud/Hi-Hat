using System;

namespace HiHat.AcquisitionHelper
{
    internal sealed class AcquireRequest
    {
        public string acquisition_id { get; set; }
        public string provider_track_id { get; set; }
        public string title { get; set; }
        public string artist { get; set; }
        public string album { get; set; }
        public double duration_seconds { get; set; }
        public string quality { get; set; }
    }

    internal sealed class AcquisitionJob
    {
        public string acquisition_id { get; set; }
        public string status { get; set; }
        public string title { get; set; }
        public string artist { get; set; }
        public string local_path { get; set; }
        public long bytes_received { get; set; }
        public ulong? bytes_total { get; set; }
        public string error_code { get; set; }
        public string error_message { get; set; }
        public DateTime updated_at { get; set; }
    }
}
