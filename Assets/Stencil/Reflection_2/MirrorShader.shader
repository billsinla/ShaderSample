Shader "Unlit/MirrorShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NoiseTex("噪声纹理", 2D) = "white" {}
		[Space(10)]
		_MirrorVisableDistance("镜像可视最大深度", Range(0,4)) = 4
		[Space(10)]
		_MirrorMinAlpha("镜面物体最小透明度", Range(0,1)) = 0
		_MirrorMaxAlpha("镜面物体最大透明度", Range(0,1)) = 1
		[Space(10)]
		_NoiseUVOffsetSpeedX("噪音UV X轴偏移速度", Range(0,10)) = 1
		_NoiseUVOffsetSpeedY("噪音UV Y轴偏移速度", Range(0,10)) = 1
		[Space(10)]
		_NoiseOffset("噪音偏移值的整体偏移值", Range(0,0.9)) = 0.25
		[Space(10)]
		_NoiseScaleX("噪音缩放值X", Range(0,1)) = 1
		_NoiseScaleY("噪音缩放值Y", Range(0,1)) = 1
		[Space(10)]
		//注意无扰动衰减，并不是无噪音偏移值的意思！衰减是针对噪音偏移值进行的
		_NoiseAttenWeight("噪音偏移衰减权重(0时完全无扰动衰减，1时有扰动衰减）", Range(0,1)) = 1
		[Space(10)]
		_AlphaFScale("透明度衰减敏感度", Range(0, 5)) = 1
	}
	SubShader
	{
		//位于Plane之后渲染，注意看Queue是Geometry+2，目的是为了进行模板测试
		Tags { "RenderType" = "Transparent" "Queue" = "Geometry+2" }
		
		Pass
		{
			Cull front //裁剪正面 因为镜面的物体是倒立的物体，背面是优先渲染的 可注释掉这句代码来看问题
			ZTest Always //总是通过深度测试
			ZWrite Off	 //禁止深度写入
			Blend SrcAlpha OneMinusSrcAlpha //开启混合
			//镜面物体渲染只有通过模板测试，即模板值为1的部分渲染
			Stencil{
				Ref 1
				Comp Equal
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
 
			#include "UnityCG.cginc"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};
 
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
				float4 worldNormal : TEXCOORD2;
			};
 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float3 planeNormal; //平面法线(世界空间的归一化平面Y轴向量)
			float3 planePos;	//平面位置(世界坐标）
			float _MirrorVisableDistance;
			float _MirrorMinAlpha;
			float _MirrorMaxAlpha;
			float _NoiseUVOffsetSpeedX;
			float _NoiseUVOffsetSpeedY;
			float _NoiseOffset;
			fixed _NoiseScaleX;
			fixed _NoiseScaleY;
			fixed _NoiseAttenWeight;
			float _AlphaFScale;
			v2f vert(appdata v)
			{				
				v2f o;
				//1. 计算物体和平面距离distance 和 镜面下的顶点位置worldPos（世界空间）
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 p = worldPos.xyz - planePos.xyz;
				float distance = dot(planeNormal, p); //dot(planeNormal, normalize(p)) * length(p); //Plane平面与物体顶点的垂直距离
				worldPos.xyz = worldPos.xyz + (-planeNormal) * (distance * 2); //反向偏移2倍距离得到新的顶点位置(世界空间)
 
				o.worldPos.xyz = worldPos.xyz;
				o.worldPos.w = distance;  //w值存储distance
 
				float alpha = lerp(_MirrorMaxAlpha, _MirrorMinAlpha, _AlphaFScale * (distance / _MirrorVisableDistance));
 
				o.worldNormal.xyz = UnityObjectToWorldNormal(v.normal).xyz;
				o.worldNormal.w = alpha; //w值存储alpha
 
				o.vertex = mul(UNITY_MATRIX_VP, worldPos); //世界转裁剪空间
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				if (i.worldPos.w > _MirrorVisableDistance) discard; //距离大于可视距离抛弃
				if (i.worldNormal.w <= 0) discard; //透明度小于等于0抛弃
 
				float3 dir = i.worldPos.xyz - planePos; //注意此时worldPos是原物体顶点位置的反向位置(它是从顶点着色器计算出来的）
				half d = dot(dir, planeNormal);
				if (d > 0) discard; //超出镜面抛弃，在镜面下方d<=0
 
				//获取噪声值
				float2 offsetXY = float2(tex2D(_NoiseTex, i.uv + fixed2(_Time.x * _NoiseUVOffsetSpeedX, 0)).r,
					tex2D(_NoiseTex, i.uv + fixed2(0, _Time.x * _NoiseUVOffsetSpeedY)).r);
				offsetXY -= _NoiseOffset;                       //噪音偏移向量 整体偏移
				offsetXY *= fixed2(_NoiseScaleX, _NoiseScaleY); //噪音偏移向量 缩放
 
				//当_NoiseAttenWeight=1时，模拟水面-越深的图像偏移越大，越浅的图像偏移越小
				//当_NoiseAttenWeight=0时，水面下的图像都进行噪音偏移(影响程度一样）
				float noiseAtten = i.worldPos.w / _MirrorVisableDistance; //扰动衰减值(0~1) 越近镜面的噪音偏移值越小（完全贴近的为0），否则反之
				noiseAtten = lerp(1, noiseAtten, _NoiseAttenWeight); //_NoiseAttenWeight为0时，无扰动 此时噪音偏移值影响最大, 反之，越远平面的噪音偏移越大
				offsetXY *= noiseAtten;  //噪音偏移向量 衰减
 
				fixed4 col = tex2D(_MainTex, i.uv + offsetXY);
				return fixed4(col.rgb, i.worldNormal.w);
			}
			ENDCG
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
				float3 worldPos : TEXCOORD1;
			};
 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float3 planeNormal;
			float3 planePos;
			v2f vert(appdata v)
			{
				v2f o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				float3 dir = i.worldPos - planePos;//注意此时的worldPos是正常的物体顶点世界位置
				half d = dot(dir, planeNormal);
				if (d < 0) discard; //正常物体渲染时，低于镜面的抛弃
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}