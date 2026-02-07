package com.lighttalk.app.storage

import com.lighttalk.core.storage.FileStorageService
import com.lighttalk.core.storage.PresignedUrlResponse
import org.slf4j.LoggerFactory
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.stereotype.Service
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest
import software.amazon.awssdk.services.s3.model.PutObjectRequest
import software.amazon.awssdk.services.s3.presigner.S3Presigner
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest
import java.net.URI
import java.time.Duration

@Service
@EnableConfigurationProperties(R2StorageProperties::class)
class R2FileStorageService(
    private val properties: R2StorageProperties
) : FileStorageService {

    private val log = LoggerFactory.getLogger(javaClass)

    private val credentials by lazy {
        StaticCredentialsProvider.create(
            AwsBasicCredentials.create(properties.accessKey, properties.secretKey)
        )
    }

    private val presigner by lazy {
        S3Presigner.builder()
            .region(Region.of("auto"))
            .endpointOverride(URI.create(properties.endpoint))
            .credentialsProvider(credentials)
            .build()
    }

    private val s3Client by lazy {
        S3Client.builder()
            .region(Region.of("auto"))
            .endpointOverride(URI.create(properties.endpoint))
            .credentialsProvider(credentials)
            .build()
    }

    override fun generatePresignedUploadUrl(
        path: String,
        contentType: String,
        contentLength: Long
    ): PresignedUrlResponse {
        val putObjectRequest = PutObjectRequest.builder()
            .bucket(properties.bucket)
            .key(path)
            .contentType(contentType)
            .contentLength(contentLength)
            .build()

        val presignRequest = PutObjectPresignRequest.builder()
            .signatureDuration(Duration.ofMinutes(5))
            .putObjectRequest(putObjectRequest)
            .build()

        val presignedRequest = presigner.presignPutObject(presignRequest)
        val uploadUrl = presignedRequest.url().toString()
        val publicUrl = "${properties.publicUrl}/$path"

        log.debug("Generated presigned URL for path: {}", path)

        return PresignedUrlResponse(
            uploadUrl = uploadUrl,
            publicUrl = publicUrl
        )
    }

    override fun delete(path: String) {
        try {
            val deleteRequest = DeleteObjectRequest.builder()
                .bucket(properties.bucket)
                .key(path)
                .build()
            s3Client.deleteObject(deleteRequest)
            log.info("Deleted file: {}", path)
        } catch (e: Exception) {
            log.error("Failed to delete file: {}", path, e)
        }
    }
}
