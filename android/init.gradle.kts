// Force all subprojects to use compileSdk 36
allprojects {
    afterEvaluate {
        extensions.findByName("android")?.apply {
            javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                .invoke(this, 36)
        }
    }
}
