Shader "Unlit/StencilOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _RefValue("Stencil RefValue",Int) = 0
        _Outline("Outline Width",Range(0,0.1)) = 0.05
        _OutlineColor("Outline Color",Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Stencil
        {
            Ref [_RefValue]
            Comp Equal
            Pass IncrSat
        }

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
            
        //渲染偏大用于描边效果黑色模型
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
    
            struct a2v
            {
                   float4 vertex : POSITION;
                   float3 normal : NORMAL;
            };
    
            struct v2f
            {
                    float4 pos : SV_POSITION;
            };
    
            fixed _Outline;
            fixed4 _OutlineColor;
    
            v2f vert(a2v v)
            {
                    v2f o;
                    //对其各个顶点沿法向扩张一点点达到膨胀效果
                    v.vertex = v.vertex + float4(normalize(v.normal) *_Outline,1);
                    o.pos =  UnityObjectToClipPos(v.vertex);
                    return o;
            }
    
            //这里只返回黑色颜色噢
            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        } 
    }
}
