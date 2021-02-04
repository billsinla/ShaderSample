using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpotTest : MonoBehaviour
{
    private static readonly int SpotPosId = Shader.PropertyToID("_SpotPos");
    private static readonly int SpotDirId = Shader.PropertyToID("_SpotDir");
    private static readonly int SpotAttenuationId = Shader.PropertyToID("_SpotAttenuation");
    private static readonly int SpotLightColorId = Shader.PropertyToID("_SpotLightColor");

    public Color SpotLightColor = Color.white;
    public float SpotAngle = 30.0f;
    public float LightRange = 50.0f;
    public float Strength = 1.0f;


    private void Update()
    {
        SetupSpotLight();
    }

    private void SetupSpotLight()
    {
        var matrix = transform.localToWorldMatrix;
        Vector4 pos = matrix.GetColumn(3);
        
        Vector4 dir = matrix.GetColumn(2);
        dir.x = -dir.x;
        dir.y = -dir.y;
        dir.z = -dir.z;

        Vector4 attenuation = Vector4.zero;
        attenuation.w = 1f;

        attenuation.x = 1f / Mathf.Max(LightRange * LightRange, 0.00001f);

        float outerRad = Mathf.Deg2Rad * 0.5f * SpotAngle;
        float outerCos = Mathf.Cos(outerRad);
        float outerTan = Mathf.Tan(outerRad);
        float innerCos = Mathf.Cos(Mathf.Atan(46f / 64f) * outerTan);
        float angleRange = Mathf.Max(innerCos - outerCos, 0.001f);
        attenuation.z = 1f / angleRange;
        attenuation.w = -outerCos * attenuation.z;

        var color = SpotLightColor * Strength;
        
        Shader.SetGlobalVector(SpotPosId, pos);
        Shader.SetGlobalVector(SpotDirId, dir);
        Shader.SetGlobalVector(SpotLightColorId, color);
        Shader.SetGlobalVector(SpotAttenuationId, attenuation);
    }
}
