using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public struct Wave
{
    public Wave(float length, float speed, float directionAngle, float phase, float h)
    {
        this.k = 2 * Mathf.PI / length;
        this.phaseSpeed = this.k * speed;
        this.phase = phase;

        var radAngle = Mathf.Deg2Rad * directionAngle;
        this.dir = new Vector2(Mathf.Cos(radAngle), Mathf.Sin(radAngle));

        this.q = Mathf.Exp(this.k * h) / k;
    }

    public Vector2 dir;
    public float q;
    //public float d;
    public float k;
    public float phaseSpeed;
    public float phase;

    public static int GetSize()
    {
        return sizeof(float) * 6;
    }
}
