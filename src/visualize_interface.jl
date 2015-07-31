const SHARED_DEFAULTS = @compat(Dict(
    :model      	  => Input(eye(Mat4f0)),
    :light      	  => Input(Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20,1)]),
    :preferred_camera => :perspective
))

visualize_default(value::Any, style::Style, kw_args=Dict{Symbol, Any}) = error("""There are no defaults for the type $(typeof(value)), 
	which either means the implementation is incomplete or not implemented yet.
	Consider defining visualize_default(::$(typeof(value)), ::Style, parameters::Dict{Symbol, Any}) => Dict{Symbol, Any} and 
	visualize(::$(typeof(value)), ::Style, parameters::Dict{Symbol, Any}) => RenderObject""")

function visualize_default(value::Any, style::Symbol, kw_args::Vector{Any}, defaults=SHARED_DEFAULTS)
	parameters_dict 		= Dict{Symbol, Any}(kw_args)
	parameters_calculated 	= visualize_default(value, Style{style}(), parameters_dict)
	merge(defaults, parameters_calculated, parameters_dict)
end

visualize(value::Any, 	  style::Symbol=:default; kw_args...) = visualize(value,  Style{style}(), visualize_default(value, 	      style, kw_args))
visualize(signal::Signal, style::Symbol=:default; kw_args...) = visualize(signal, Style{style}(), visualize_default(signal.value, style, kw_args))
visualize(file::File, 	  style::Symbol=:default; kw_args...) = visualize(read(file), style; kw_args...)


function view(
		robj::RenderObject, screen=ROOT_SCREEN; 
		method 	 = robj.uniforms[:preferred_camera], 
		position = Vec3f0(2), lookat=Vec3f0(0)
	)
	if method == :perspective
		camera = get!(screen.cameras, :perspective) do 
			PerspectiveCamera(screen.inputs, position, lookat)
		end
	elseif method == :fixed_pixel
		camera = get!(screen.cameras, :fixed_pixel) do 
			DummyCamera(window_size=screen.area)
		end
	elseif method == :orthographic_pixel
		camera = get!(screen.cameras, :orthographic_pixel) do 
			OrthographicPixelCamera(screen.inputs)
		end
	elseif method == :nothing
		return push!(screen.renderlist, robj)
	else
		error("Method $method not a known camera type")
	end
	merge!(robj.uniforms, collect(camera))
	push!(screen.renderlist, robj)
end

view(robjs::Vector{RenderObject}, screen=ROOT_SCREEN; kw_args...) = for robj in robjs
	view(robj, screen; kw_args...)
end
