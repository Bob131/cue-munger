[CCode (cheader_filename = "uchardet.h")]
namespace CharsetDetect {
    [CCode (cname = "uchardet_t", cprefix = "uchardet_", free_function = "uchardet_delete")]
    [Compact]
    public class Context {
        public int handle_data(string data, size_t len);
        public void data_end();
        public unowned string get_charset();
        public Context();
    }
}
