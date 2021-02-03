Shader "Unlit/PlaneShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_ColorTint("_Color Tint", Color) = (1,1,1,1)
	}
	SubShader
	{
		//Queue是Geometry+1，它会在MirrorShader之前渲染。即先于镜面反射的物体渲染，为了写入模板值1
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry+1" }
		LOD 300
		//模板测试,写入模板值为1，目的：只让镜面部分产生镜面效果，利用了模板测试进行的操作
		Stencil
		{
			Ref 1
			Comp Always
			Pass Replace
		}
		CGPROGRAM
		
		#pragma surface surf Lambert finalcolor:mycolor
		#pragma target 3.0
		sampler2D _MainTex;
		sampler2D _BumpTex;
		fixed4 _ColorTint;
		struct Input {
			float2 uv_MainTex;			
		};
		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb;
			o.Alpha = tex.a;
		}
		void mycolor(Input IN, SurfaceOutput o, inout fixed4 color) {
			color = color * _ColorTint;
		}
		ENDCG
	}
	FallBack "Legacy Shaders/Diffuse"
}