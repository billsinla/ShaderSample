Shader "Bill/UberSprite"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap ("Pixel Snap", Float) = 0
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0

        [Toggle(USE_PIXELATE)] _UsePixelate("Use Pixel Style", Int) = 0
        _PixelResolution("Pixel Resolution", Range(4,1024)) = 32

        [Toggle(USE_BLUR)] _UseBlur("Use Blur", Int) = 0
        _BlurIntensity("BlurIntensity", Float) = 0.1

        [Toggle(USE_DESATURATE)] _UseDesaturate("Use Desaturate", Int) = 0
        _DesaturateFactor("DesaturateFactor", Range(0,1)) = 1

        [Toggle(USE_SHADOW)] _UseShadow("Use Shadow", Int) = 0
        _ShadowColor("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowOffset("ShadowOffset", Vector) = (0.1,0.1,0,0)

        [Toggle(USE_CHROMATIC_ABERRATION)] _UseChromaticAberr("Use Chromatic Aberration", Int) = 0
        _ChromaticAberrFactor("Chromatic Factor", Range(0, 1)) = 1
        _ChromaticAberrAlpha("Chromatic Alpha", Range(0, 1)) = 0.4

        [Toggle(USE_OUTLINE)] _UseOutline("Use Outline", Int) = 0
        _OutlineColor("Outline Base Color", Color) = (0,0,0,1)
        _OutlineWidth_Alpha_Glow("OutlineWidth_Alpha_Glow", Vector) = (0.001,1,1,0)

        [Toggle(USE_INNER_OUTLINE)] _UseInnerOutline("Use InnerOutline", Int) = 0
        _InnerOutlineColor("Inner Outline Color", Color) = (0,0,0,1)
        _InnerOutlineWidth_Alpha_Glow("InnerOutlineWidth_Alpha_Glow", Vector) = (0.001,1,1,0)
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment Frag
            #pragma target 2.0

            #pragma multi_compile_instancing
            #pragma multi_compile _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA

            #include "UnitySprites.cginc"
            #include "ShaderLib/Util2D.cginc"

            #pragma shader_feature USE_PIXELATE
            #pragma shader_feature USE_BLUR
            #pragma shader_feature USE_DESATURATE
            #pragma shader_feature USE_SHADOW
            #pragma shader_feature USE_CHROMATIC_ABERRATION
            #pragma shader_feature USE_OUTLINE
            #pragma shader_feature USE_INNER_OUTLINE

            #ifdef USE_PIXELATE
            fixed _PixelResolution;
            #endif

            #ifdef USE_BLUR
            fixed _BlurIntensity;
            #endif

            #ifdef USE_DESATURATE
            fixed _DesaturateFactor;
            #endif

            #ifdef USE_SHADOW
            fixed2 _ShadowOffset;
            fixed _ShadowAlpha;
            fixed4 _ShadowColor;
            #endif

            #ifdef USE_CHROMATIC_ABERRATION
            fixed _ChromaticAberrFactor;
            fixed _ChromaticAberrAlpha;
            #endif

            #if USE_OUTLINE
            fixed4 _OutlineColor;
            fixed4 _OutlineWidth_Alpha_Glow;
            #endif

            #if USE_INNER_OUTLINE
            fixed4 _InnerOutlineColor;
            fixed4 _InnerOutlineWidth_Alpha_Glow;
            #endif

            void UVOperate(inout float2 uv)
            {
                float2 rawUV = uv;
                #ifdef USE_PIXELATE
                uv = Pixelate(uv, _PixelResolution);
                #endif
            }

            void ColorOperate(float2 rawUV, float2 uv, float4 inColor, inout float4 col)
            {
                #ifdef USE_BLUR
                //col = OldPhoto(col, _BlurIntensity);
                col = Blur(_MainTex, rawUV, _BlurIntensity);
                #endif

                #ifdef USE_SHADOW
                col = Shadow2D(col, _MainTex, rawUV, _ShadowOffset, _ShadowColor);
                #endif

                #ifdef USE_CHROMATIC_ABERRATION
                col = ChromaticAberration(col, _MainTex, rawUV, inColor * _Color, _ChromaticAberrFactor,
                                          _ChromaticAberrAlpha);
                #endif

                #ifdef USE_DESATURATE
                col = Desaturate(col, _DesaturateFactor);
                #endif

                #if USE_INNER_OUTLINE
                col = DrawInnerOutline(col, _MainTex, rawUV, _InnerOutlineColor, _InnerOutlineWidth_Alpha_Glow.x,
                                       _InnerOutlineWidth_Alpha_Glow.y, _InnerOutlineWidth_Alpha_Glow.z);
                #endif

                #ifdef USE_OUTLINE
                col = DrawOutline(col, _MainTex, rawUV, _OutlineColor, _OutlineWidth_Alpha_Glow.x,
                                  _OutlineWidth_Alpha_Glow.y, _OutlineWidth_Alpha_Glow.z);
                #endif
            }

            fixed4 Frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float2 rawUV = uv;
                UVOperate(uv);

                fixed4 col = SampleSpriteTexture(uv) * IN.color;
                ColorOperate(rawUV, uv, IN.color, col);

                col.rgb *= col.a;
                return col;
            }
            ENDCG
        }
    }
    CustomEditor "UberSpriteGUI"
}