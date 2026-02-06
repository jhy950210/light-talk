package com.lighttalk.core.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Table

@Entity
@Table(name = "users")
class User(

    @Column(nullable = false, unique = true)
    val email: String,

    @Column(name = "password_hash", nullable = false)
    var passwordHash: String,

    @Column(nullable = false, length = 50)
    var nickname: String,

    @Column(name = "profile_image_url", length = 512)
    var profileImageUrl: String? = null

) : BaseEntity()
