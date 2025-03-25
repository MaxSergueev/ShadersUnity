Shader "Custom/Flag"
{
    Properties
    {
        _Color("Color", Color) = (1, 0, 0, 1)
        _MainTex("Main Texture", 2D) = "white"{}
        _Speed("Speed", float) = 1.0
        _Frequency("Frequency", float) = 1.0
        _Amplitude("Amplitude", float) = 1.0
    }

    SubShader
    {
        Tags{
       "Queue" = "Transparent"
       "RenderType" = "Transparent"
       "IgnoreProjector" = "True"
       }

        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            float _Speed;
            float _Frequency;
            float _Amplitude;

            float4 vertexAnimFlag(float4 pos, float2 uv)
            {
               pos.z = pos.z + sin((uv.x - _Time.y * _Speed) * _Frequency) * _Amplitude * uv.x;
               return pos ;
            }


            struct appdata
            {
                float4 vertex : POSITION;
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
                v.vertex = vertexAnimFlag(v.vertex, v.texcoord);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.texcoord) * _Color;
            }
            ENDCG
        }
    }
}
