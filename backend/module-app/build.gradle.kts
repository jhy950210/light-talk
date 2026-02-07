dependencies {
    implementation(project(":module-core"))
    implementation(project(":module-auth"))
    implementation(project(":module-user"))
    implementation(project(":module-chat"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-security")
    runtimeOnly("org.postgresql:postgresql")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // AWS SDK for S3 (Cloudflare R2 compatible)
    implementation(platform("software.amazon.awssdk:bom:2.25.16"))
    implementation("software.amazon.awssdk:s3")
}

tasks.getByName<org.springframework.boot.gradle.tasks.bundling.BootJar>("bootJar") {
    enabled = true
}

tasks.getByName<Jar>("jar") {
    enabled = false
}
