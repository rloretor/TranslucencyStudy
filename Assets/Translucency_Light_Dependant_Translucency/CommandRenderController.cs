using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

public class CommandRenderController : MonoBehaviour
{
    public CameraEvent WhenToRender;
    public Transform MeshTransform;
    public Shader DepthShader;

    protected Dictionary<Camera, CommandBuffer> _CommandBufferMap = new Dictionary<Camera, CommandBuffer>();
    protected Mesh _mesh;
    protected Material _depthMaterial;

    public void OnWillRenderObject()
    {
        if (!this.isActiveAndEnabled)
        {
            if (DepthShader == null || MeshTransform == null)
            {
                Debug.LogWarning("Careful, some of our dependencies might not be assigned");
            }

            Cleanup();
            return;
        }

        TryInitMesh();
        TryInitMaterial();
        CleanNullCameras();
        TrySetCommandBuffer();
        ConfigureDrawing();
    }

    protected virtual void ConfigureDrawing()
    {
    }

    private void TrySetCommandBuffer()
    {
        var cam = Camera.current;

        CommandBuffer commandBuffer = null;
        if (_CommandBufferMap.ContainsKey(cam))
        {
            _CommandBufferMap[cam].Clear();
            return;
        }

        commandBuffer = new CommandBuffer()
        {
            name = cam.name + " " + GetType().ToString()
        };

        cam.AddCommandBuffer(WhenToRender, commandBuffer);
        _CommandBufferMap.Add(cam, commandBuffer);

        foreach (var entry in _CommandBufferMap)
        {
            Debug.Log($"{entry.Key.name} has {entry.Value.name} associated");
        }
    }

    private void TryInitMesh()
    {
        if (_mesh == null || _mesh != MeshTransform.GetComponent<MeshFilter>().sharedMesh)
        {
            _mesh = MeshTransform.GetComponent<MeshFilter>().sharedMesh;
        }
    }

    private void TryInitMaterial()
    {
        if (_depthMaterial == null)
        {
            _depthMaterial = new Material(DepthShader)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
        }
    }

    private void OnDestroy()
    {
        Cleanup();
    }

    private void CleanNullCameras()
    {
        _CommandBufferMap = _CommandBufferMap.Select(x => x).Where(x => x.Key != null)
            .ToDictionary(x => x.Key, x => x.Value);
    }

    [ContextMenu("Cleanup")]
    private void Cleanup()
    {
        foreach (var entry in _CommandBufferMap)
        {
            entry.Value.Release();
            if (entry.Key == null) continue;
            entry.Key.RemoveAllCommandBuffers();
        }

        _CommandBufferMap.Clear();
    }
}