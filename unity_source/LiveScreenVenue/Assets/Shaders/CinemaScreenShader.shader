Shader "LiveScreen/CinemaScreen"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _FitParams ("Fit Params (scaleX, scaleY, offsetX, offsetY)", Vector) = (1, 1, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        Cull Back
        Lighting Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWorld : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _FitParams; // x: scaleX, y: scaleY, z: offsetX, w: offsetY

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normalWorld = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // CRITICAL FACE CHECK:
                // Unity's primitive Cube has 6 faces sharing a single material slot.
                // The front screen face faces into the auditorium (+Z in local space).
                // Ensure side, top, bottom, and back surfaces are always pure black.
                // In world space, screen front normal points along the screen transform's forward.
                // A local normal check or world normal check ensures only the front face displays video.
                // Since normalWorld.z > 0.5 (or screen facing into room), non-front faces return pure black.
                if (i.normalWorld.z < 0.2)
                {
                    return fixed4(0, 0, 0, 1);
                }

                // In Unity's built-in Cube mesh, looking at the front face from the audience:
                // pos.x = -0.5 (viewer left) has uv.x = 1.0
                // pos.x = +0.5 (viewer right) has uv.x = 0.0
                // Map to normalized viewer coordinates (u = 0 at left, 1 at right; v = 0 at bottom, 1 at top):
                float u = 1.0 - i.uv.x;
                float v = i.uv.y;

                float scaleX = _FitParams.x;
                float scaleY = _FitParams.y;
                float offsetX = _FitParams.z;
                float offsetY = _FitParams.w;

                // Check if the current pixel is inside the fitted video area
                if (u < offsetX || u > (offsetX + scaleX) ||
                    v < offsetY || v > (offsetY + scaleY))
                {
                    // Cinema letterbox / pillarbox black bars
                    return fixed4(0, 0, 0, 1);
                }

                // Map to normalized 0..1 video texture coordinates
                float2 videoUV = float2(
                    (u - offsetX) / scaleX,
                    (v - offsetY) / scaleY
                );

                return tex2D(_MainTex, videoUV);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
