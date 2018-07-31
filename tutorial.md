## ThreeJS Exercise:

### By Alex Bogartz

### Setting up our scene

Let’s start with a simple shader example. The first thing we want to do is create a basic HTML page and import our scripts. We’re going to need the basic ThreeJS library, a loader to load the model file, and some camera controls.

```
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Medieval House</title>
    <script src="http://threejs.org/build/three.js"></script>
    <script src="js/OBJLoader.js"></script>`
    <script src="js/controls.js"></script>
    <style media="screen">
        body {
            overflow: hidden;
        }

        pre {
            display: none;
        }

        #container {
            width: 500px;
            height: 500px;
        }
    </style>

    </head>

    <body>
      <section id='container'></section>
      <script></script>
	</body>
    </html>
```

Next, we want to set up our ThreeJS scene. Update the script tag.

```
<script>
 	var container, camera, scene, renderer, uniforms;

    init();
    animate();
    function init() {
            camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 10000);
            camera.position.z = 500;
            controls = new THREE.OrbitControls(camera);
            scene = new THREE.Scene();

            renderer = new THREE.WebGLRenderer({ antialias: false });
            renderer.setSize(window.innerWidth, window.innerHeight);

            container = document.getElementById('container');
            container.appendChild(renderer.domElement);
    }

    function animate() {
        requestAnimationFrame(animate);
        render();
    }

     function render() {
        renderer.render(scene, camera);
     }

</script>
```

At this point, if we run our code, we should only see a blank screen. That's because we're not loading anything into our scene. Let's try adding some code to use ThreeJS's OBJ loader utility.

```
...
scene = new THREE.Scene();
var loader = new THREE.OBJLoader();
loader.load('models/house.obj', function (object) {  
   object.position.y = -100;
   scene.add(object);
 });
```

Ok, so we still have a blank screen. This is because even though we have a loaded OBJ model, there is no material for the model. A material is code that tells WebGL how to render the model's vertices. We need to create one, and this is where we start writing our shader.

First, let's add some script tags to start our vertex and fragment shaders

```
  ...
  <section id='container'></section>
  <script id='vertexShader' type='x-shader/x-vertex'>
        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
  </script>

   <script id='fragmentShader' type='x-shader/x-fragment'>
      void main() {
         gl_FragColor = vec4(1.0 , 1.0, 1.0, 1.0);
      }
  </script>
```

Next, let's create our material.

```
 ...
 scene = new THREE.Scene();
 var material = new THREE.ShaderMaterial({
    uniforms: {},
    vertexShader: document.getElementById('vertexShader').textContent,
    fragmentShader: document.getElementById('fragmentShader').textContent
});
...
```

We also have to update the JavaScript to apply the material to the loaded model.

```
...
loader.load('models/house.obj', function (object) {
    object.position.y = -100;
    object.traverse(function (child) {
        if (child instanceof THREE.Mesh) {
            child.material = material;
        }
    });
    scene.add(object);
    ...
```

We now have a scene! If you drag your mouse around, the house should be totally white. For extra credit, try changing some of the frag color variables to see how you can change the color of the house.

But this isn't very interesting, so let's try and add a real texture to the house.
Let's add a little more code to our init function.

```
...
scene = new THREE.Scene();

uniforms = {
    uTexture: { type: "t", value: THREE.ImageUtils.loadTexture("textures/house-diffuse.png") }
};
...
```

Here, we're creating our first Uniforms. Uniforms are values we can send into the shader as inputs from JavaScript. We're setting a `uTexture` uniform that will tell our shader the material which texture to use.

So let's update the material:

```
var material = new THREE.ShaderMaterial({
   uniforms: uniforms,
   vertexShader: document.getElementById('vertexShader').textContent,
   fragmentShader: document.getElementById('fragmentShader').textContent
});
```

We've now added the uniforms object to our material object. Now we can just update our shader

```
  ...
  <section id='container'></section>
  <script id='vertexShader' type='x-shader/x-vertex'>
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
  </script>

   <script id='fragmentShader' type='x-shader/x-fragment'>
      varying vec2 vUv;
      uniform sampler2D uTexture;
      void main() {
          gl_FragColor = texture2D(uTexture, vUv);
      }
  </script>
  ...
```

We're inserting our first `varying` variable. This is a variable that can be passed from the vertex shader to the fragment shader. It's called a varying because it can change from pixel to pixel. In this case, we're passing the position of the fragment as it relates to the model's `UV` space.

Our scene is shaping up! We now have a loaded model with a texture. We should be able to rotate the model and zoom in and out of the scene.

### More Detail

While our scene looks alright, it can be improved by adding lighting, using a _normal_ map and a _specular_ map. A normal map is an image with RGB values that correspond to both direction and height. Each color corresponds to a direction in 3D space. So the _blue_ color stands for how high the surface is raised, while _red_ and _green_ correspond to the _x_ and _y_ direction. Let's do a little more with our shader.

First, let's update our inputs to the vertex shader.

```
varying vec2 vUv;
varying vec3 normalInterp;
varying vec3 vertPos;

void main() {
    vUv = uv;
    vec4 vertPos4 = modelViewMatrix * vec4(position, 1.0);
    vertPos = vec3(vertPos4) / vertPos4.w;
    normalInterp = normalMatrix * normal;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
```

We're adding a few more details to tell our fragment shader where in _eye space_ each vertex is. Think of eye space as 3D space as it pertains to the perspective of the viewer.

Now let's also update our fragment shader by adding these variables above our main function.

```
 // Inputs
uniform sampler2D uTexture;
uniform sampler2D uNormal;
uniform sampler2D uSpec;

varying vec2 vUv;
varying vec3 normalInterp;
varying vec3 vertPos;

// Constants
const vec3 lightPos 	= vec3(200,60,100);
const vec3 ambientColor = vec3(0.1, .1, .1);
const vec3 specColor 	= vec3(1.0, 1.0, 1.0);
```

In addition to adding two new textures and carrying over our new varyings, we've also added a light, an ambient color, and a specular color. Each of these will help us shape the final effect.

Let's add a new method to our _fragment_ shader. So far, we've only had a `main` method. That is the method that runs for every shader. But like any programming language, we can write other methods to help us encapsulate chunks of code. This method will be called `perturbNormal`.

```
...
const vec3 specColor 	= vec3(1.0, 1.0, 1.0);

// Function for calculating normal maps
vec3 perturbNormal( vec3 eye_pos, vec3 surf_norm, vec2 uv_coords, vec3 normal_perturbation ) {
    vec3 q0 = dFdx( eye_pos.xyz );
    vec3 q1 = dFdy( eye_pos.xyz );
    vec2 st0 = dFdx( uv_coords.st );
    vec2 st1 = dFdy( uv_coords.st );

    vec3 S = normalize( q0 * st1.t - q1 * st0.t );
    vec3 T = normalize( -q0 * st1.s + q1 * st0.s );
    vec3 N = normalize( surf_norm );
    mat3 tsn = mat3( S, T, N );

    return normalize( tsn * normal_perturbation );
}

void main() {
...
```

If you run the code now, you should get an error in the console telling us that the `GL_OES_standard_derivatives` extension is disabled. This is because ThreeJS does not include extensions as part of the default shader. `dFdx` and `dFdy` are derivative functions. They return a _tangent_ and a _bitangent_ to our surface normal, and we need them to calculate the bump map. Let's fix it!

```
...
var material = new THREE.ShaderMaterial({
   uniforms: uniforms,
   vertexShader: document.getElementById('vertexShader').textContent,
   fragmentShader: document.getElementById('fragmentShader').textContent,
   extensions: {
       derivatives: true,
   }
);
...
```

Our scene should be loading again.

We're almost done! Let's add a few more lines to our fragment shader's `main` method.

```
void main() {
     vec3 mapN = texture2D( uNormal, vUv ).xyz * 2.0 - 1.0;
     vec3 normal = normalize(normalInterp);
     normal = perturbNormal(vertPos, normal, vUv, mapN);
```

We're using our normal map and our new function to slightly adjust the surface normal, _per pixel_, based on the details of the image's RGB values.

```
    vec3 lightDir = normalize(lightPos - vertPos);
    float lambertian = max(dot(lightDir,normal), 0.0);
```

Next, we're taking the light direction (the difference between the light position and the vertex position) and using that value to get Lambert shading.

```
    float specular = 0.0;
    if(lambertian > 0.0) {
        // Calculate fresnel value

        vec3 viewDir = normalize(-vertPos);
        vec3 halfDir = normalize(lightDir + viewDir);
        float specAngle = max(dot(halfDir, normal), 0.0);
        specular = pow(specAngle, 16.0);
    }
```

What is fresnel? Fresnel is an approximation of the fact that as a surface turns away from us, it becomes more reflective. We can use this to adjust the specular light reflection based on whether or not a surface is facing the camera.

Finally, we can put them all together to light our scene.

```
vec3 diffuseColor = texture2D(uTexture, vUv).rgb;

vec3 specularColor = texture2D(uSpec, vUv).rgb;
specular = specular * (specularColor.r +specularColor.g +specularColor.b) / 3.0;
gl_FragColor = vec4(ambientColor + lambertian * diffuseColor + specular * specColor, 1.0);
```

One last thing, if you save the work here, you'll notice that something is wrong. That's because we also need to update our _uniforms_ in JavaScript.

```
uniforms = {
    uTexture: { type: "t", value: THREE.ImageUtils.loadTexture("textures/house-diffuse.png") },
    uNormal: { type: "t", value: THREE.ImageUtils.loadTexture("textures/house-normal.png") },
    uSpec: { type: "t", value: THREE.ImageUtils.loadTexture("textures/house-spec.png") }
;
```
