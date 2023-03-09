shader_type sky;
render_mode use_half_res_pass;
uniform sampler2D star_sky;
uniform sampler2D moon;
uniform vec4 moon_tint: source_color;
uniform vec4 clouds_tint: source_color;
uniform bool SCATERRING; 
uniform vec3 SUN_POS; //normalize this vector in script!
uniform vec3 MOON_POS; //normalize this vector in script
uniform vec3 MOON_TEX_POS; //normalize this vector in script!!
uniform vec3 LIGHTING_POS;//normalize this vector in script!!
uniform float lighting_strength;

uniform float MOON_PHASE:hint_range(-1.1,1.1);
uniform float moon_size:hint_range(0.0,0.5);
uniform float sun_radius:hint_range(0.0,0.3);
uniform float attenuation:hint_range(0.0,1.0);

// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds and https://www.shadertoy.com/view/4dsXWn for 2d clouds
uniform vec3 WIND; //wind_vec*wind_str направление ветра, вектор*силу ветра
uniform float SIZE :hint_range(0.0,10.0); //0.5
uniform float SOFTNESS :hint_range(0.0,10.0); //0.5
uniform float COVERAGE :hint_range(0.0,1.0); //0.5
uniform float HEIGHT :hint_range(0.0,1.0); //0.0
uniform float THICKNESS :hint_range(0.0,100.0); //25.
uniform float ABSORPTION :hint_range(0.0,10.0); //1.030725
uniform int STEPS :hint_range(0,100); //25

lowp float noise( in lowp vec3 pos )
{
    pos*=0.01;
	lowp float  z = pos.z*256.0;
	lowp vec2 offz = vec2(0.317,0.123);
	lowp vec2 uv = pos.xy + offz*floor(z);
	return mix(textureLod( moon, uv ,0.0).b,textureLod( moon, uv+offz ,0.0).b,fract(z));
}

lowp float get_noise(lowp vec3 p, lowp float FBM_FREQ)
{
	lowp float
	t  = 0.51749673 * noise(p); p *= FBM_FREQ;
	t += 0.25584929 * noise(p); p *= FBM_FREQ;
	t += 0.12527603 * noise(p); p *= FBM_FREQ;
	t += 0.06255931 * noise(p);
	return t;
}

bool SphereIntersect(lowp vec3 apos, lowp float arad, lowp vec3 ro, lowp vec3 rd, out lowp vec3 norm)
{
    ro -= apos;
    lowp float A = dot(rd, rd);
    lowp float B = 2.0*dot(ro, rd);
    lowp float C = dot(ro, ro)-arad*arad;
    lowp float D = B*B-4.0*A*C;
    if (D < 0.0) return false;
    D = sqrt(D);
    A *= 2.0;
    lowp float t1 = (-B+D)/A;
    lowp float t2 = (-B-D)/A;
    if (t1 < 0.0) t1 = t2;
    if (t2 < 0.0) t2 = t1;
    t1 = min(t1, t2);
    if (t1 < 0.0) return false;
    norm = ro+t1*rd;
    return true;
}

lowp float density(lowp vec3 pos, lowp vec3 offset)
{
	lowp vec3 p = pos * 0.02/SIZE + offset;
	lowp float dens = get_noise(p,2.0+SOFTNESS);
	dens *= smoothstep (COVERAGE, COVERAGE + .07, dens);
	return clamp(dens, 0.0, 1.0);	
}

lowp vec4 clouds_3d(lowp vec3 ro, lowp vec3 rd, lowp vec3 wind)
{
	lowp vec3 apos=vec3(0, -450, 0);
	lowp float arad=500.0;
    lowp vec3 clouds = vec3(0.0);
	lowp float alpha = 0.0;
    lowp vec3 norm;
    if(SphereIntersect(apos,arad,ro,rd,norm)){
        lowp int steps = STEPS;
        lowp float march_step = THICKNESS / float(steps);
        lowp vec3 dir_step = rd / rd.y * march_step;
        lowp vec3 pos =norm;
        lowp float T = 1.0;
        for (int i = 0; i < steps; i++)
		 {
            if (length(pos) > 1e3) break;
		lowp float dens = density (pos, wind)*march_step;
		lowp float T_i = exp(-ABSORPTION * dens);
            T *= T_i;
          if (T < .01) break;
		lowp float h = float(i) / float(steps);
        clouds += T * (exp(h)/2.0 ) *dens;
		alpha += (1. - T_i) * (1. - alpha);
            pos += dir_step;
			}
		}
		return vec4(clouds,alpha);
}

lowp vec3 cube_bot(lowp vec3 p, lowp vec3 c1, lowp vec3 c2, lowp float time)
{
	lowp float f = 0.0;
	f += .50000 * noise(.5 * (p+vec3(0.,0.,-time*0.275)));
	f += .25000 * noise(1. * (p+vec3(0.,0.,-time*0.275)));
	f += .12500 * noise(2. * (p+vec3(0.,0.,-time*0.275)));
	f += .06250 * noise(4. * (p+vec3(0.,0.,-time*0.275)));
	return  f* mix(c1, c2, p * .5 + .5);
}

lowp vec3 extra_cheap_atmosphere(vec3 raydir, vec3 sundir) //https://www.shadertoy.com/view/MtBcz1
{
	sundir.y = max(sundir.y, -0.07);
	lowp float special_trick = 1.0 / (raydir.y + 0.2);
	//special_trick = 1.0 / (raydir.y * 1.0 + 0.1);//original code
	lowp float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
	lowp float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
	lowp float sundt = pow(max(0.0, dot(sundir, raydir)), 8.0);
	lowp float mymie = sundt * special_trick * 0.2;
	lowp vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - vec3(5.5, 13.0, 22.4) / 22.4), special_trick2); //original code
	lowp vec3 sky = max(vec3(0.0), vec3(5.5, 13.0, 22.4) / 22.4 * suncolor - vec3(5.5, 13.0, 22.4) * 0.004 * (special_trick + -6.0 * sundir.y * sundir.y));//original code
	sky *= special_trick * (0.24 + raysundt * 0.24);
	sky = sky + mymie * suncolor;
	sky += smoothstep(0.997, 0.999, dot(raydir, sundir));//sun_disk
	return clamp(sky,0.0,1.0);
} 

lowp vec2 uv_sphere(lowp vec3 rd, lowp vec3 pos, lowp float scale) //someone else's code, there are problems with the movement of the moon on y-axis
{
	lowp vec3 ord = normalize(rd + 2.0*cross(pos, cross(pos, rd)));
	vec2 uv =vec2(atan(ord.x,ord.y),acos(ord.z));
	if (uv.x<0.0) uv.x+=3.1415926536*2.0;
	uv /= vec2(3.1415926536*2.0, 3.1415926536);
	uv=(uv-0.5)/scale+0.5;
	uv.x*=2.0;uv.x-=0.5;
	return uv;
}

lowp vec2 draw_moon(lowp vec3 rd) 
{
	lowp vec2 uv=uv_sphere(rd,MOON_TEX_POS,moon_size);
	lowp float moon_amount = texture(moon,uv).r*smoothstep(moon_size*1.44,moon_size*1.0,length(MOON_POS-rd));//+min(pow(max(dot(rd, MOON_POS), 0.0), 500.0/moon_radius) * 100.0, 1.0);
	lowp float moon_mask = moon_amount;
	moon_amount*=1.0 - attenuation; //attenuation of the brightness of the moon (for sunrise and sunset).
	moon_amount = clamp(mix (0.0,moon_amount,smoothstep(0.9,1.0,(1.0-moon_size)*0.5+length(MOON_POS-rd+MOON_PHASE)*(1.0-moon_size*0.75))),0.001,1.0);//here we cast a shadow on the moon. moon phase. 	
	return vec2(moon_amount,moon_mask);
}

lowp vec3 draw_night_sky (lowp float sky_amount, lowp vec3 rd, lowp vec2 sky_coords, lowp float cld_alpha)
{
	lowp vec2 moon_amount = draw_moon(rd);
	lowp float stars = texture(star_sky,sky_coords).r; // mipmap off for correct steching; starfield texture from this https://opengameart.org/content/night-sky-skybox-generator ande convert to panorama with this https://danilw.github.io/GLSL-howto/cubemap_to_panorama_js/cubemap_to_panorama.html
	stars *= step(max (max(cld_alpha, sky_amount),moon_amount.y),0.001);
	return stars + moon_tint.rgb*moon_amount.x*(clamp(1.0-cld_alpha-0.2,0.0,1.0));//Here we mix with the clouds so that there is no black border. But so that the Moon does not Shine through the clouds.
}

void sky() {
	vec3 rd = EYEDIR;
	rd.x*=-1.0; //The x-axis is inverted on the godot scene for unknown reasons
	lowp vec3 ro = vec3(0.0, -200.0*HEIGHT+40.0, 0.0); //This is the vector of displacement of the sphere relative to zero coordinates. Here you can set the height of the clouds. That is, to make a sphere with clouds higher or lower.
	lowp vec4 cld;
	bool quality_res_cloud;
	if (AT_HALF_RES_PASS)
	{
		lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
		lowp float horizonPow =1.0-pow(1.0-abs(skyPow), 5.0);
		lowp float horizon_line = clamp((1.0 - exp(-10. * pow(max((0.0), horizonPow), (2.6)))),0.0,1.0);//Here we dissolve the clouds in the horizon for a smooth transition to the horizon line.
		if (rd.y>0.0) {cld=clouds_3d(ro,rd,WIND*TIME/SIZE);}
		else{cld.rgb = cube_bot(rd,vec3(1.5,1.49,1.71), vec3(1.1,1.15,1.5),TIME); cld.a = 1.0;}
		cld*=horizon_line;
		COLOR = vec3(cld.r,cld.a,0.0);
	}
	else 
	{
	lowp vec4 clouds;
	clouds.rgb = HALF_RES_COLOR.r*clouds_tint.rgb*attenuation;
	clouds.a = HALF_RES_COLOR.g;
	lowp vec3 sky;
	sky = extra_cheap_atmosphere(rd,SUN_POS);
	sky = mix (vec3(0.0),sky,smoothstep(-0.1,0.0,rd.y));
	sky = max (sky,draw_night_sky(max(max(sky.b,sky.r),sky.g),rd,SKY_COORDS,clouds.a));
	lowp float lighting = clamp (0.5+texture(moon,LIGHTING_POS.xz-rd.xz+0.5).g*smoothstep(0.6,0.3,length(LIGHTING_POS-rd)),0.0,1.0);
	sky = mix (sky.rgb, vec3(lighting),lighting_strength); //flash of light in the sky simulates a lightning strike
	sky = mix(sky, clouds.rgb/(0.0001+clouds.a), clouds.a);
	COLOR = sky;
	}
}