//
//  FlyingCamera.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 23/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import simd

struct FlyingCamera {
    var vEye = float3(0, 0, 2)
    var vView = float3(0, 0, -1)
    var vUp: float3 = float3(0, 1, 0)
    let fSpeed: Float = 0.5
    let fSensitivity: Float = 0.005
    
    // Performs updates of camera - moving and rotating.
    mutating func update(deltaX: Float, deltaY: Float, cameraTranslation: (x: Float, z: Float)) {
        RotateWithMouse(deltaX: deltaX, deltaY: deltaY)
        
        // Get view direction
        var vMove = vView-vEye
        vMove = normalize(vMove)
        vMove *= fSpeed
        
        var vStrafe = cross(vView-vEye, vUp);
        vStrafe = normalize(vStrafe);
        vStrafe *= fSpeed;
        
        //var iMove = 0;
        var vMoveBy = float3(0, 0, 0)
        let move: Float = RenderUtils.shared.moveSpeedX
     
        // Get vector of move
        if cameraTranslation.z < 0 {
            vMoveBy += vMove * move
        }
        if cameraTranslation.z > 0 {
            vMoveBy -= vMove * move
        }
        if cameraTranslation.x < 0 {
            vMoveBy -= vStrafe * move
        }
        if cameraTranslation.x > 0 {
            vMoveBy += vStrafe * move
        }
        vEye += vMoveBy
        vView += vMoveBy
    }
    
    // Checks for moving of mouse and rotates camera.
    mutating func RotateWithMouse(deltaX: Float, deltaY: Float)
    {
        
            let sdeltaX = -deltaX * fSensitivity
            let sdeltaY = -deltaY * fSensitivity
        
        if sdeltaX != 0.0 {
            vView -= vEye;
            let rotationMatrix = simd_quaternion(sdeltaX, simd_float3(0.0, 1.0, 0.0))//float4x4(rotationAbout: float3(0.0, 1.0, 0.0), by: deltaX)
            vView = float3x3(rotationMatrix) * vView //rotate(vView, deltaX, float3(0.0, 1.0, 0.0))
            vView += vEye;
        }
        if sdeltaY != 0.0 {
            var vAxis = cross(vView-vEye, vUp)
            vAxis = normalize(vAxis)
            let fAngle = sdeltaY
            let fNewAngle = fAngle + GetAngleX()
            if fNewAngle > -89.80 && fNewAngle < 89.80 {
                
                vView -= vEye
                let rotationMatrix = simd_quaternion(sdeltaY, vAxis)
                vView = float3x3(rotationMatrix) * vView //rotate(vView, deltaY, vAxis);
                vView += vEye;
            }
        }
    }
    
    // Gets X angle of camera (head turning up and down).
    func GetAngleX() -> Float {
        var vDir = vView - vEye;
        vDir = normalize(vDir);
        var vDir2 = vDir
        vDir2.y = 0.0
        vDir2 = normalize(vDir2);
        var fAngle = acos(dot(vDir2, vDir))*(180.0/Float.pi);
        if vDir.y < 0 {
            fAngle *= -1.0
        }
        return fAngle;
    }
    
    func Look() -> float4x4 {
        var Matrix = float4x4(0)
        
        var X, Y, Z: float3
        
        Z = vEye - vView;
        Z = normalize(Z)
        Y = vUp;
        X = cross(Y, Z)
        
        Y = cross(Z, X)
        
        X = normalize(X)
        Y = normalize(Y)
        
        Matrix[0][0] = X.x;
        Matrix[1][0] = X.y;
        Matrix[2][0] = X.z;
        Matrix[3][0] = -dot(X, vEye);
        Matrix[0][1] = Y.x;
        Matrix[1][1] = Y.y;
        Matrix[2][1] = Y.z;
        Matrix[3][1] = -dot(Y, vEye);
        Matrix[0][2] = Z.x;
        Matrix[1][2] = Z.y;
        Matrix[2][2] = Z.z;
        Matrix[3][2] = -dot(Z, vEye);
        Matrix[0][3] = 0;
        Matrix[1][3] = 0;
        Matrix[2][3] = 0;
        Matrix[3][3] = 1.0;
        
        return Matrix;
    }
}
