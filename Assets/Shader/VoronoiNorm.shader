Shader "Custom/VoronoiNorm"
{
    Properties
    {
        _Color1("Color 1", Color) = (1, 0, 0, 1)
        _Color2("Color 2", Color) = (0, 0, 1, 1)
        _MainTex("Main Texture", 2D) = "white"{}
        _Speed("Speed", float) = 1.0
        _Frequency("Frequency", float) = 1.0
        _Amplitude("Wave height", float) = 0.1

    }

    SubShader
    {
        Tags{
       "Queue" = "Transparent"
       "RenderType" = "Transparent"
       "IgnoreProjector" = "True"
       }

        LOD 100
        CULL OFF

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float4 _Color1;
            uniform float4 _Color2;
            uniform float _Speed;
            uniform float _Frequency;
            uniform float _Amplitude;

            struct appdata
            {
                float4 vertex: POSITION;
                float4 normal: NORMAL;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 texcoord: TEXCOORD0;
            };

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                float displacement = tex2Dlod(_MainTex, v.texcoord * _MainTex_ST);
                
                o.vertex = UnityObjectToClipPos(v.vertex + (v.normal * displacement*_Amplitude));
                //o.vertex.y = v.vertex.y + sin( (v.texcoord.x - _Time.y * _Speed) *_Frequency) * _Amplitude;

                
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                float4 color = tex2D(_MainTex, i.texcoord);
                return color.r * _Color1 + (1 - color.r) * _Color2;
            }
            ENDCG
        }
    }
}
