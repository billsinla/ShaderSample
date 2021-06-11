Shader "Bill/UberParticleEffect"
{
    Properties
    {
        [Header(ColorTint)]
        _TintColor("TintColor ",Color) = (0.5,0.5,0.5,0.5)
        _ColorFactor("ColorFactor ",Float) = 1

        [Header(MainTex)]
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainSpeed2_MaskSpeed2 ("MainSpeed2_MaskSpeed2", Vector) = (0,0,0,0)

        [Header(Mask)]
        _MaskTex ("MaskTex", 2D) = "white" {}

        [Header(Distortion)]
        _DistortTex ("DistortTex", 2D) = "white" {}
        _DistortSpeed2_Factor2 ("DistortSpeed2_Factor2", Vector) = (1,1,1,1)
        _DistortUVFactor2_RotateSpeed1(" DistortUVFactor2_RotateSpeed1 ",Vector) = (1,1,0,0)

        [Header(Dissolve)]
        _DissolveTex("DissolveTex", 2D) = "white" {}
        _DissolveProgress("DissolveProgress", Range( 0 , 1)) = 0
        [HDR] _DissolveColor ("DissolveColor", Color) = (1,1,1,1)
        _DissolveRange("DissolveRange", Range( 0 , 1)) = 0.5
        _IsClipDissolve("IsClipDissolve", Int) = 0

        [Header(SoftParticle)]
        [Toggle(USE_SOFTPARTICLES)] _UseSoftParticle("Use Soft Particle", Int) = 0
        _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0 // soft particles

        [Space]
        [Header(Rendering)]
        [Enum(Cull Off,0, Cull Front,1, Cull Back,2)]
        _CullMode("Culling", Float) = 0 //0 = off, 2=back
        [KeywordEnum(Additive,Blend,Opaque,Cutout,Transparent,Subtractive,Modulate)]
        _BlendMode("Blend Mode", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("SrcBlend", Int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("DstBlend", Int) = 10
        [HideInInspector] _BlendOp ("__blendop", Float) = 0.0
        _ZWrite("ZWrite On", Int) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        LOD 100

        Lighting Off
        BlendOp [_BlendOp]
        Blend[_SrcBlend][_DstBlend]
        Cull[_CullMode]
        ZWrite[_ZWrite]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "ShaderLib/Util.cginc"

            #pragma shader_feature USE_MASK
            #pragma shader_feature USE_DISTORT
            #pragma shader_feature USE_DISSOLVE
            #pragma shader_feature USE_SOFTPARTICLES
            #pragma shader_feature USE_FLOW_DISTORT
            #pragma shader_feature USE_CLIP_DISSOLVE

            float4 _TintColor;
            float _ColorFactor;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainSpeed2_MaskSpeed2;

            //遮罩
            #ifdef  USE_MASK
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            #endif

            //扭曲
            #ifdef  USE_DISTORT
            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float4 _DistortSpeed2_Factor2;
            float4 _DistortUVFactor2_RotateSpeed1;
            #endif

            //溶解
            #ifdef  USE_DISSOLVE
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            float _DissolveProgress;
            fixed4 _DissolveColor;
            float _DissolveRange;
            #endif

            //软粒子
            #ifdef  USE_SOFTPARTICLES
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float _InvFade;
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 customData : TEXCOORD0;
                float4 MainUV2_MaskUV2 : TEXCOORD1;

                #if defined(USE_DISTORT) || defined(USE_DISSOLVE)
                float4 DistortUV2_DissolveUV2 : TEXCOORD2;
                #endif

                #ifdef USE_SOFTPARTICLES
                float4 projPos : TEXCOORD3;
                #endif
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.customData.xy = v.uv.zw;

                float2 uv = v.uv.xy;
                o.MainUV2_MaskUV2.xy = uv * _MainTex_ST.xy + _MainTex_ST.zw;

                #ifdef USE_MASK
                o.MainUV2_MaskUV2.zw = uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
                #endif

                #ifdef USE_DISTORT
                o.DistortUV2_DissolveUV2.xy = uv * _DistortTex_ST.xy + _DistortTex_ST.zw;
                #endif

                #ifdef USE_DISSOLVE
                o.DistortUV2_DissolveUV2.zw = uv * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
                #endif

                #ifdef USE_SOFTPARTICLES
                o.projPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                #endif

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #ifdef USE_SOFTPARTICLES
                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                float partZ = i.projPos.z;
                float fade = saturate(_InvFade * (sceneZ - partZ));
                i.color.a *= fade;
                #endif

                float time = _Time.y;
                fixed maskVal = 1;
                fixed2 mainUV = i.MainUV2_MaskUV2.xy + _MainSpeed2_MaskSpeed2.xy * time;

                //遮罩
                #ifdef USE_MASK
                fixed2 maskUV = i.MainUV2_MaskUV2.zw + _MainSpeed2_MaskSpeed2.zw * time;
                maskVal *= tex2D(_MaskTex, maskUV).r;
                #endif

                //扭曲
                #ifdef USE_DISTORT
                float2 distortUV = 0;

                #ifdef USE_FLOW_DISTORT
                half2 distort1 = SAMPLE_DISTORT_TEX(_DistortTex,
                                                    i.DistortUV2_DissolveUV2.xy + _DistortSpeed2_Factor2.xy * time);
                half2 distort2 = SAMPLE_DISTORT_TEX(_DistortTex,
                                                    i.DistortUV2_DissolveUV2.xy + float2(0.37, 0.71) +
                                                    _DistortSpeed2_Factor2.xy * time * 1.3) * 0.7;
                distortUV += (distort1 + distort2);
                #else
                distortUV += SAMPLE_DISTORT_TEX(_DistortTex,i.DistortUV2_DissolveUV2.xy);
                #endif

                distortUV *= maskVal;
                mainUV += distortUV * _DistortUVFactor2_RotateSpeed1.xy; //add distort
                mainUV = Rotate2D(mainUV, _Time.y * _DistortUVFactor2_RotateSpeed1.z);
                #endif

                fixed4 mainCol = tex2D(_MainTex, mainUV);

                //溶解
                #ifdef USE_DISSOLVE
                float customData = i.customData.x;
                float progress = customData + _DissolveProgress;
                float dissolveVal = tex2D(_DissolveTex, i.DistortUV2_DissolveUV2.zw).r * mainCol.a;

                float dissolveBorderVal = saturate((dissolveVal - progress));
                dissolveBorderVal = saturate(1 - smoothstep(0, _DissolveRange, dissolveBorderVal)) * step(
                    dissolveBorderVal, _DissolveRange);

                mainCol = lerp(mainCol, _DissolveColor, dissolveBorderVal);

                #ifdef USE_CLIP_DISSOLVE
                clip(dissolveVal - progress);
                #else
                mainCol.a = saturate(dissolveVal - progress);
                //mainCol *= saturate(dissolveVal - progress);
                #endif

                #endif

                fixed4 finalCol = mainCol * i.color * _TintColor * (maskVal * _ColorFactor);
                return finalCol;
            }
            ENDCG
        }
    }
    CustomEditor "UberParticleGUI"
}