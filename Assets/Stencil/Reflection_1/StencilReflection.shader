Shader "Unlit/StencilReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _RefValue("Ref Value",Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        //[_RefValue] 就是我们自己设置的参考值
        //Equal 表示了只有和缓冲值相等才通过测试,物体才能被显示出来
        //Keep 表示通过模板测试或深度测试失败后,都保留原有缓冲值.
        
        //这里渲染虚像的Pass，正常的渲染
        Pass
        {
            Stencil{
                Ref [_RefValue]
                Comp Equal
                Pass keep
                ZFail keep
            }
            //因为虚像经过镜像反转，位置也发生了变换，陷入了镜子世界中。所以势必会深度测试失败。
            //作用无论深度测试是什么结果都算通过深度测试。
            ZTest Always

            //剔除掉模型的正面（即虚像的背面），显示模型的反面（即虚像的正面）。
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            fixed4 _Color;
            
            //声明float4x4类型的_WtoMW矩阵，来接受脚本传递来的矩阵
            float4x4 _WtoMW;
            

            v2f vert (appdata v)
            {
                v2f o;
                //首先将模型顶点转换至世界空间坐标系
                float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
                //再把顶点从世界空间转换至镜子空间
                float4 mirrorWorldPos = mul(_WtoMW,worldPos);
                //最后就后例行把顶点从世界空间转换至裁剪空间
                o.vertex = mul(UNITY_MATRIX_VP,mirrorWorldPos);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // Transform the normal from object space to world space
                //o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col * _Color;
            }
            ENDCG
        }
        
        //这里渲染实像的Pass，正常的渲染
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col * _Color;
            }
            ENDCG
            
            
        }
    }
}
