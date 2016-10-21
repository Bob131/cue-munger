public static int main(string[] args) {
    Test.init(ref args);
    Test.set_nonfatal_assertions();

    Test.add_func("/eac-test", eac_test);
    Test.add_func("/eac-test/pathological", pathological_eac_test);
    Test.add_func("/non-latin-test", non_latin_test);
    Test.add_func("/utf16-test", utf16_test);

    Test.run();
    return 0;
}
