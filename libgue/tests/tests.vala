public static int main(string[] args) {
    Test.init(ref args);
    Test.set_nonfatal_assertions();

    Test.add_func("/eac-test", eac_test);

    Test.run();
    return 0;
}