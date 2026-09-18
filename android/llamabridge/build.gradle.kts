plugins {
    id("com.android.library")
}

android {
    namespace = "com.platicasay.llamabridge"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        minSdk = 26
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_STL=c++_shared")
                cppFlags += listOf("-O3", "-fexceptions")
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("../../native/llama/CMakeLists.txt")
        }
    }
}
