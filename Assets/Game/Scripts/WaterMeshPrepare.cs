using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class WaterMeshPrepare : MonoBehaviour
{
    [SerializeField] private float _cellSize = 1f;
    [SerializeField] private bool _buildOnAwake = false;

    private Mesh CreateMesh()
    {
        var filter = GetComponent<MeshFilter>();
        var meshSize = Vector3.zero;

#if UNITY_EDITOR
        if (!UnityEditor.EditorApplication.isPlaying)
            meshSize = filter.sharedMesh.bounds.size;
        else
            meshSize = filter.mesh.bounds.size;
#else
        meshSize = filter.mesh.bounds.size;
#endif

        var scale = Vector3.Scale(meshSize, transform.lossyScale);

        var mesh = new Mesh();
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        var width = Mathf.CeilToInt(scale.x / _cellSize);
        var length = Mathf.CeilToInt(scale.z / _cellSize);
        var verticesWidth = width + 1;
        var verticesLength = length + 1;
        var vertices = new Vector3[verticesWidth * verticesLength];
        var uvs = new Vector2[vertices.Length];
        var triangles = new int[length * width * 6];

        for (int z = 0; z < verticesLength; z++)
        {
            for (int x = 0; x < verticesWidth; x++)
            {
                var vertexIndex = z * verticesWidth + x;

                vertices[vertexIndex] = new Vector3(x - width / 2, 0, z - length / 2) * _cellSize;
                uvs[vertexIndex] = new Vector2(x, z);
            }
        }

        for (int z = 0; z < length; z++)
        {
            for (int x = 0; x < width; x++)
            {
                var offset = (x + z * width) * 6;

                triangles[offset + 0] = x + z * verticesWidth;
                triangles[offset + 1] = x + (z + 1) * verticesWidth;
                triangles[offset + 2] = (x + 1) + (z + 1) * verticesWidth;

                triangles[offset + 3] = (x + 1) + (z + 1) * verticesWidth;
                triangles[offset + 4] = (x + 1) + z * verticesWidth;
                triangles[offset + 5] = x + z * verticesWidth;
            }
        }

        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.RecalculateNormals();
        mesh.SetUVs(0, uvs);

        return mesh;
    }

    [ContextMenu("Build")]
    public void Build()
    {
        GetComponent<MeshFilter>().mesh = CreateMesh();

        transform.localScale = Vector3.one;
    }

    private void Awake()
    {
        if (_buildOnAwake)
            Build();
    }
}
