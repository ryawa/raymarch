#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;

struct light
{
    vec3 pos;
    vec3 intensity;
    float attenuation;
    float ambient;
};

struct material
{
    vec3 color;
    vec3 specular;
    float shininess;
};

// combine primitives
float opUnion(float d1, float d2)
{
    return min(d1, d2);
}

// intersect primitives
float opIntersection(float d1, float d2)
{
    return max(d1, d2);
}

// carve primitives
float opSubtraction(float d1, float d2)
{
    return max(-d1, d2);
}

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

vec3 normal(vec3 pos)
{
    const vec2 STEP = vec2(0.0001, 0.0);
    float gx = SDF(pos + STEP.xyy) - SDF(pos - STEP.xyy);
    float gy = SDF(pos + STEP.yxy) - SDF(pos - STEP.yxy);
    float gz = SDF(pos + STEP.yyx) - SDF(pos - STEP.yyx);
    return normalize(vec3(gx, gy, gz));
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

// calculate phong lighting, adapted from https://www.tomdalling.com/blog/modern-opengl/07-more-lighting-ambient-specular-attenuation-gamma/
vec3 phong(vec3 surfacePos, vec3 camPos, light l, material m)
{
    vec3 n = normal(surfacePos);
    vec3 surfaceToLight = normalize(l.pos - surfacePos);
    vec3 surfaceToCam = normalize(camPos - surfacePos);
    vec3 reflection = reflect(-surfaceToLight, n);
    float distToLight = length(l.pos - surfacePos);

    vec3 ambient = l.ambient * m.color * l.intensity;

    float diffuseCoefficient = max(0.0, dot(n, surfaceToLight));
    vec3 diffuse = diffuseCoefficient * m.color * l.intensity;

    float specularCoefficient = 0.0;
    if (diffuseCoefficient > 0.0)
    {
        specularCoefficient = pow(max(0.0, dot(surfaceToCam, reflection)), m.shininess);
    }
    vec3 specular = specularCoefficient * m.specular * l.intensity;

    float attenuation = 1.0 / (1.0 + l.attenuation * pow(distToLight, 2.0));
    return ambient + attenuation * (diffuse + specular);
}

// render scene
vec3 render(vec3 rayOrigin, vec3 rayDir)
{
    const vec3 gamma = vec3(1.0 / 2.2);
    light l = light(vec3(1.0, 1.0, 1.0), vec3(1.0), 1.0, 0.05);
    material m = material(vec3(0.3, 0.8, 0.2), vec3(1.0), 10.0);
    float depth = castRay(rayOrigin, rayDir);
    if (depth < 0.0)
    {
        // skybox
        return vec3(0.3, 0.3, 0.6) - (rayDir.y * 0.25);
    }
    vec3 color = phong(rayOrigin + rayDir * depth, rayOrigin, l, m);
    return pow(color, gamma);
}

void main()
{
    vec3 camPos = vec3(0.0, 0.0, 2.0);
    vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
    vec3 camDir = vec3(uv, -1.0);
    gl_FragColor = vec4(render(camPos, camDir), 1.0);
}