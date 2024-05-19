using NaughtyAttributes;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEditor.Searcher.SearcherWindow.Alignment;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

public class Water : MonoBehaviour
{
    ~Water()
    {
        _wavesBuffer.Release();
    }

    private ComputeBuffer _wavesBuffer;

    private Material _waterMaterial;
    [SerializeField] private int _wavesCount = 1;
    [SerializeField, Range(-180, 180f)] private float _direction = 0;
    [SerializeField, MinMaxSlider(-180, 180f)] private Vector2 _directionAngle = new(-45, 45);
    [SerializeField] private float _length = 2 * Mathf.PI;
    [SerializeField, MinMaxSlider(0f, 2 * Mathf.PI)] private Vector2 _phase = new(0, 2 * Mathf.PI);
    [SerializeField] private float _speed = 1;
    [SerializeField] private float _lagrangianHeight = 0;
    [SerializeField] private float _fbmAmplitudeMutiplier = 0.5f;
    [SerializeField] private float _fbmLengthMultiplier = 2f;

    private ComputeBuffer CreateWavesBuffer()
    {
        if (_wavesBuffer != null)
        {
            _wavesBuffer.Release();
        }

        _wavesBuffer = new ComputeBuffer(_wavesCount, Wave.GetSize());
        var waves = new List<Wave>();
        var amplitudeMultiplier = 1f;
        var lengthMultiplier = 1f;

        for (int i = 0; i < _wavesCount; i++)
        {
            var length = _length * lengthMultiplier;
            var speed = _speed;
            var directionAngle = i == 0 ? _direction : Random.Range(_directionAngle.x, _directionAngle.y);
            var phase = Random.Range(_phase.x, _phase.y);

            var wave = new Wave(length, speed, directionAngle, phase, _lagrangianHeight);

            waves.Add(wave);

            amplitudeMultiplier *= _fbmAmplitudeMutiplier;
            lengthMultiplier *= _fbmLengthMultiplier;
        }

        _wavesBuffer.SetData(waves);

        return _wavesBuffer;
    }

    private void Awake()
    {
        _waterMaterial = GetComponent<MeshRenderer>().material;

        _waterMaterial.SetBuffer("_Waves", CreateWavesBuffer());
        _waterMaterial.SetInteger("_WavesCount", _wavesCount);
    }

#if UNITY_EDITOR

    [ContextMenu("Regenerate waves")]
    private void RegenerateWavesBuffer()
    {
        _waterMaterial.SetBuffer("_Waves", CreateWavesBuffer());
        _waterMaterial.SetInteger("_WavesCount", _wavesCount);
    }

#endif
}
