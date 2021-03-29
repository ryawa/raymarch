#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;

// calculate signed distance from pos to a sphere
float sphereSDF(vec3 pos, vec3 center, float radius)
{
    return length(pos - center) - radius;
}

// calculate signed distance for scene
float SDF(vec3 pos)
{
    return sphereSDF(pos, vec3(0.0), 1.0);
}

// cast ray and return the distance from the origin to the scene
float castRay(vec3 rayOrigin, vec3 rayDir)
{
    const int MAX_STEPS = 128;
    const float MAX_DEPTH = 100.0;
    const float HIT_DIST = 0.0001;
    // current depth on ray
    float depth = 0.0;
    for (int steps = 0; steps < MAX_STEPS; steps++)
    {
        // distance to closest object in scene
        float dist = SDF(rayOrigin + rayDir * depth);
        if (dist < HIT_DIST)
        {
            return depth;
        }
        else if (depth > MAX_DEPTH)
        {
            return -1.0;
        }
        // move forward by the distance to the closest object
        depth += dist;
    }
    return -1.0;
}

// render scene
vec3 render(vec3 rayOrigin, vec3 rayDir)
{
    float pos = castRay(rayOrigin, rayDir);
    if (pos < 0.0)
    {
        // skybox
        return vec3(0.3, 0.3, 0.6) - (rayDir.y * 0.25);
    }
    // simple shading
    return vec3(1.0 - pos * 0.5);
}

void main()
{
    vec3 camPos = vec3(0.0, 0.0, 2.0);
    vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
    vec3 camDir = vec3(uv, -1.0);
    gl_FragColor = vec4(render(camPos, camDir), 1.0);
}