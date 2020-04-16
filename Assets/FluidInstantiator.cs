
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public class FluidInstantiator : MonoBehaviour
{
    [SerializeField] private int instanceCount;
    [SerializeField] private Mesh instancedMesh;
    [SerializeField] private Material instancedMaterial;

    private ComputeBuffer positionsBuffer;
    private ComputeBuffer meshArgsBuffer;
    private uint[] args = new uint[5] {0, 0, 0, 0, 0};
    private static readonly int PositionBuffer = Shader.PropertyToID("positionBuffer");

    private void Start()
    {
        SetMeshBuffer();
        SetPositionBuffer();
    }

    private void Update()
    {
        Graphics.DrawMeshInstancedIndirect(instancedMesh, 0, instancedMaterial,
            new Bounds(Vector3.zero, Vector3.one * 100), meshArgsBuffer);
    }

    private void SetPositionBuffer()
    {
        positionsBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 4);
        List<Vector4> positions = new List<Vector4>(instanceCount);

        for (int i = 0; i < instanceCount; i++)

        {
            // xi as in mathematics random
            Vector4 xi = new Vector4();
            xi.x = Random.value * Random.Range(1, 5);
            xi.y = Random.value * Random.Range(1, 5);
            xi.z = Random.value * Random.Range(1, 5);
            xi.w = 1;
            positions.Add(xi);
        }


        positionsBuffer.SetData(positions.ToArray());
        instancedMaterial.SetBuffer(PositionBuffer, positionsBuffer);
    }

    private void SetMeshBuffer()
    {
        meshArgsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        args[0] = instancedMesh.GetIndexCount(0);
        args[1] = (uint) instanceCount;
        args[2] = instancedMesh.GetIndexStart(0);
        args[3] = instancedMesh.GetBaseVertex(0);

        meshArgsBuffer.SetData(args);
    }

    private void OnDestroy()
    {
        CleanupBuffers();
    }

    private void OnDisable()
    {
        CleanupBuffers();
    }

    private void CleanupBuffers()
    {
        positionsBuffer?.Release();
        meshArgsBuffer?.Release();
    }
}