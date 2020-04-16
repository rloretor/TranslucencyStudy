using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class LightDepthCommand : CommandRenderController
{
    public Light _mainLight;

    private readonly int DepthDiffId = Shader.PropertyToID("_LightDepth");
    private readonly int LightVMatrixId = Shader.PropertyToID("_lightV");


    protected override void ConfigureDrawing()
    {
        var cam = Camera.current;
        var commandBuffer = _CommandBufferMap[cam];

        commandBuffer.GetTemporaryRT(DepthDiffId, Screen.width * 2, Screen.height * 2, 0, FilterMode.Bilinear,
            RenderTextureFormat.RFloat);
        commandBuffer.SetRenderTarget(DepthDiffId);
        commandBuffer.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));

        var tempPos = cam.transform.position;
        var tempRot = cam.transform.rotation;

        SetLightVAndVPMatrix(cam, commandBuffer);
        commandBuffer.DrawMesh(_mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), _depthMaterial, 0, 0);

        cam.transform.SetPositionAndRotation(tempPos, tempRot);
        commandBuffer.SetRenderTarget(BuiltinRenderTextureType.None);
    }

    //https://answers.unity.com/questions/12713/how-do-i-reproduce-the-mvp-matrix.html
    private void SetLightVAndVPMatrix(Camera camera, CommandBuffer buffer)
    {
        bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
        var V = _mainLight.transform.worldToLocalMatrix;

        if (d3d)
        {
            // Invert XY for rendering to a render texture
            for (int i = 0; i < 4; i++)
            {
                V[2, i] = -V[2, i];
            }
        }

        buffer.SetGlobalMatrix(LightVMatrixId, V);
    }
}