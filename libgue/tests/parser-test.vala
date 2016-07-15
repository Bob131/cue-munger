public static int main(string[] args) {
    Test.init(ref args);
    Test.set_nonfatal_assertions();

    Test.run();
    return 0;
}
