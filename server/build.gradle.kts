plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.ktor)
    application
}

group = "com.blakebarrett.lore"
version = "1.0.0"
application {
    mainClass.set("com.blakebarrett.lore.ApplicationKt")
    applicationDefaultJvmArgs = listOf("-Dio.ktor.development=${extra["development"] ?: "false"}")
}


repositories {
    mavenCentral()
}

dependencies {
    implementation(projects.shared)
    implementation(libs.logback)
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty)
    testImplementation(libs.ktor.server.tests)
    testImplementation(libs.kotlin.test.junit)

    implementation("io.ktor:ktor-server-core:1.6.3")
    implementation("io.ktor:ktor-server-netty:1.6.3")
    implementation("io.ktor:ktor-gson:1.6.3")

    implementation("com.google.firebase:firebase-admin:9.2.0")
//    implementation("com.google.firebase:firebase-database:23.0.0")

    implementation(kotlin("stdlib-jdk8"))

    testImplementation("io.ktor:ktor-server-tests:1.6.3")
}