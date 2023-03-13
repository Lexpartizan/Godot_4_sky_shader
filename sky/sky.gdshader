shader_type sky;
render_mode use_quarter_res_pass;
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
uniform float attenuation:hint_range(0.0,1.0);

// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds
uniform vec3 WIND; //wind_vec*wind_str
uniform float SIZE :hint_range(0.0,10.0); //0.5
uniform float SOFTNESS :hint_range(0.0,10.0); //0.5
uniform float COVERAGE :hint_range(0.0,1.0); //0.5
uniform float HEIGHT :hint_range(0.0,1.0); //0.0
uniform float THICKNESS :hint_range(0.0,100.0); //25.
uniform float ABSORPTION :hint_range(0.0,10.0); //1.030725
uniform int STEPS :hint_range(0,100); //25
//lowp float hash(lowp vec3 p3) {p3  = fract(p3 * .1031); p3 += dot(p3, p3.zyx + 31.32); return fract((p3.x + p3.y) * p3.z);}
lowp float hash(lowp vec3 p) {p  = fract( p*0.3183099+0.1 )*17.0;return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );}
lowp float noise( lowp vec3 pos )
{
    lowp vec3 i = floor(pos); lowp vec3 f = fract(pos); f = f*f*(3.0-2.0*f);
	return mix(mix(mix( hash(i+vec3(0,0,0)), hash(i+vec3(1,0,0)),f.x),
					mix( hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)),f.x),f.y),
					mix(mix( hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)),f.x),
					mix( hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)),f.x),f.y),f.z);
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
	//lowp float A = dot(rd, rd);
	lowp float B = 2.0*dot(ro, rd);
	lowp float C = dot(ro, ro)-arad*arad;
	lowp float D = B*B-4.0*C;//lowp float D = B*B-4.0*A*C;
	if (D < 0.0) return false;
	D = sqrt(D);
	//A *= 2.0;
	lowp float t1 = (-B+D)*0.5;//lowp float t1 = (-B+D)/A;
	lowp float t2 = (-B-D)*0.5;//lowp float t2 = (-B-D)/A;
	lowp float if_op = float(t1 < 0.0); t1 =t1*(1.0-if_op)+t2*if_op;//if (t1 < 0.0) t1 = t2;
	if_op = float(t2 < 0.0); t2 =t2*(1.0-if_op)+t1*if_op; //if (t2 < 0.0) t2 = t1;
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
	if(SphereIntersect(apos,arad,ro,rd,norm))
	{
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

lowp vec3 extra_cheap_atmosphere(vec3 raydir, vec3 sundir) //https://www.shadertoy.com/view/MtBcz1
{
	sundir.y = max(sundir.y, -0.07);
	lowp float special_trick = 1.0 / (raydir.y + 0.2);//special_trick = 1.0 / (raydir.y * 1.0 + 0.1);//original code
	lowp float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
	lowp vec3 magic_sky_color = vec3(0.245535, 0.580357, 1.0);
	lowp float sun_dist = max(0.0,dot(sundir, raydir));
	lowp float mymie = pow(sun_dist, 8.0) * special_trick * 0.33;//original 0.2
	lowp vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - magic_sky_color), special_trick2);
	lowp vec3 sky = max(vec3(0.0), magic_sky_color * suncolor - magic_sky_color * 0.0896 * (special_trick + -6.0 * sundir.y * sundir.y));
	sky *= special_trick * (0.24 + pow(sun_dist, 2.0) * 0.24);
	sky = sky + mymie * suncolor;
	//sky += vec3(1.0 * smoothstep(0.1,0.0, acos(sun_dist)));
	lowp float sun =0.0;
	sun=pow(sun_dist,2048.0);//smoothstep(0.998, 0.99999, sun_dist);//sun_disk
	sky += sun;
	return clamp(sky,0.0,1.0);
} 

lowp vec2 uv_sphere(lowp vec3 rd, lowp vec3 pos, lowp float scale) //someone else's code, there are problems with the movement of the moon on y-axis
{
	lowp vec3 ord = normalize(rd + 2.0*cross(pos, cross(pos, rd)));
	vec2 uv =vec2(atan(ord.x,ord.y),acos(ord.z));
	//if (uv.x<0.0) uv.x+=3.1415926536*2.0
	uv.x+=PI*2.0*float(uv.x<0.0);
	uv /= vec2(PI*2.0, PI);
	uv=(uv-0.5)/scale+0.5;
	uv.x*=2.0;uv.x-=0.5;
	return uv;
}

lowp vec2 draw_moon(lowp vec3 rd) 
{
	lowp vec2 uv=uv_sphere(rd,MOON_TEX_POS,moon_size);
	lowp float moon_amount = texture(moon,uv).r;
	moon_amount *= 1.0-smoothstep(moon_size*1.0,moon_size*1.4,length(MOON_POS-rd));//+min(pow(max(dot(rd, MOON_POS), 0.0), 500.0/moon_radius) * 100.0, 1.0);
	lowp float moon_mask = moon_amount;
	moon_amount*=1.0 - attenuation; //attenuation of the brightness of the moon (for sunrise and sunset).
	moon_amount = clamp(mix (0.0,moon_amount,smoothstep(0.9,1.0,(1.0-moon_size)*0.5+length(MOON_POS-rd+MOON_PHASE)*(1.0-moon_size*0.75))),0.001,1.0);//here we cast a shadow on the moon. moon phase. 	
	return vec2(moon_amount,moon_mask);
}

lowp vec3 draw_night_sky (lowp float sky_amount, lowp vec3 rd, lowp vec2 sky_coords, lowp float cld_alpha)
{
	lowp vec2 moon_amount = draw_moon(rd);
	lowp float stars = texture(star_sky,sky_coords).r; // mipmap off for correct steching; starfield texture from this https://opengameart.org/content/night-sky-skybox-generator ande convert to panorama with this https://danilw.github.io/GLSL-howto/cubemap_to_panorama_js/cubemap_to_panorama.html
	stars *= step(max (max(cld_alpha, sky_amount),moon_amount.y),0.01);
	return stars + moon_tint.rgb*moon_amount.x*(clamp(1.0-cld_alpha-0.2,0.0,1.0));//Here we mix with the clouds so that there is no black border. But so that the Moon does not Shine through the clouds.
}

void sky() {
	vec3 rd = EYEDIR;
	rd.x*=-1.0; //The x-axis is inverted on the godot scene for unknown reasons
	lowp vec3 ro = vec3(0.0, -200.0*HEIGHT+40.0, 0.0); //This is the vector of displacement of the sphere relative to zero coordinates. Here you can set the height of the clouds. That is, to make a sphere with clouds higher or lower.
	lowp vec4 cld;
	bool quality_res_cloud;
	if (AT_QUARTER_RES_PASS)
	{
		lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
		lowp float horizonPow =1.0-pow(1.0-abs(skyPow), 5.0);
		lowp float horizon_line = clamp((1.0 - exp(-10. * pow(max((0.0), horizonPow), (2.6)))),0.0,1.0);//Here we dissolve the clouds in the horizon for a smooth transition to the horizon line.
		if (rd.y>0.0) 
			{cld=clouds_3d(ro,rd,WIND*TIME/SIZE);}
		else
			//{cld.rgb = cube_bot(rd,vec3(1.5,1.49,1.71), vec3(1.1,1.15,1.5),TIME); cld.a = 1.0;}
			{cld.rgb = vec3(get_noise(rd+WIND*TIME,3.0));cld.a =1.0;;}
		cld*=horizon_line;
		COLOR = vec3(cld.r,cld.a,0.0);
	}
	else 
	{
	lowp vec4 clouds;
	clouds.rgb = QUARTER_RES_COLOR.r*clouds_tint.rgb*attenuation;
	clouds.a = QUARTER_RES_COLOR.g;
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