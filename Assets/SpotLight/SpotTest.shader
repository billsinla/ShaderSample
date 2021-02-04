Shader "Unlit/SpotTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            uniform float4 _SpotPos;
            uniform float4 _SpotDir;
            uniform float4 _SpotAttenuation;
            uniform float4 _SpotLightColor;

            float3 GetSpotLight (float3 normal, float3 worldPos) {

                float3 lightColor = _SpotLightColor.rgb;
                float4 lightPos = _SpotPos;
                float4 lightAttenuation = _SpotAttenuation;
                float3 sportDir = _SpotDir.xyz;

                float3 lightVector = lightPos.xyz - worldPos;
                float3 lightDir = normalize(lightVector);
                float diffuse = saturate(dot(normal, lightDir));

                float rangeFade = dot(lightVector, lightVector) * lightAttenuation.x;
                rangeFade = saturate(1.0 - rangeFade * rangeFade);
                rangeFade *= rangeFade;

                float spotFade = dot (sportDir, lightDir);
                spotFade = saturate(spotFade * lightAttenuation.z + lightAttenuation.w);
                spotFade *= spotFade;

                float distanceSqr = max (dot(lightVector, lightVector), 0.00001);
                diffuse *= 1.0 * spotFade * rangeFade / distanceSqr;

                return diffuse * lightColor;
            }
            
            v2f vert (appdata v)
            {
                v2f o;

                o.clipPos = UnityObjectToClipPos(v.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float3 diffuseLight = GetSpotLight(i.normal, i.worldPos);

                //return _SpotDir;
                //return float4 (diffuseLight.xyz, 1.0);

                return float4(col.xyz * diffuseLight.xyz, 1.0);
            }
            ENDCG
        }
    }
}
