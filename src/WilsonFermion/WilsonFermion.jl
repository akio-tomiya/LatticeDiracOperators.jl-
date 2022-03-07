include("./WilsoncloverFermion.jl")


struct Wilson_Dirac_operator{Dim,T,fermion} <: Dirac_operator{Dim}  where T <: AbstractGaugefields
    U::Array{T,1}
    boundarycondition::Vector{Int8}
    _temporary_fermi::Vector{fermion}
    γ::Array{ComplexF64,3}
    rplusγ::Array{ComplexF64,3}
    rminusγ::Array{ComplexF64,3}
    κ::Float64 #Hopping parameter
    r::Float64 #Wilson term
    hopp::Array{ComplexF64,1}
    hopm::Array{ComplexF64,1}
    eps_CG::Float64
    MaxCGstep::Int64
    verbose_level::Int8
    method_CG::String
    cloverterm::Union{Nothing,WilsonClover}
    verbose_print::Verbose_print
    _temporary_fermion_forCG::Vector{fermion}
    #verbose::Union{Verbose_1,Verbose_2,Verbose_3}
end



struct Wilson_Dirac_operator_evenodd{Dim,T,fermion} <: Dirac_operator{Dim}  where T <: AbstractGaugefields
    parent::Wilson_Dirac_operator{Dim,T,fermion}
    function Wilson_Dirac_operator_evenodd(D::Wilson_Dirac_operator{Dim,T,fermion}) where {Dim,T,fermion} 
        new{Dim,T,fermion}(D)
    end
end


struct DdagD_Wilson_operator{Dim,T,fermion} <: DdagD_operator 
    dirac::Wilson_Dirac_operator{Dim,T,fermion}
    function DdagD_Wilson_operator(U::Array{<: AbstractGaugefields{NC,Dim},1},x,parameters) where  {NC,Dim}
        return new{Dim,eltype(U),typeof(x)}(Wilson_Dirac_operator(U,x,parameters))
    end

    function DdagD_Wilson_operator(D::Wilson_Dirac_operator{Dim,T,fermion}) where {Dim,T,fermion}
        return new{Dim,T,fermion}(D)
    end
end

struct γ5D_Wilson_operator{Dim,T,fermion} <: γ5D_operator
    dirac::Wilson_Dirac_operator{Dim,T,fermion}
    function γ5D_Wilson_operator(U::Array{<: AbstractGaugefields{NC,Dim},1},x,parameters) where  {NC,Dim}
        return new{Dim,eltype(U),typeof(x)}(Wilson_Dirac_operator(U,x,parameters))
    end

    function γ5D_Wilson_operator(D::Wilson_Dirac_operator{Dim,T,fermion}) where {Dim,T,fermion}
        return new{Dim,T,fermion}(D)
    end
end


include("./WilsonFermion_4D.jl")

include("./WilsonFermion_4D_wing.jl")
include("./WilsonFermion_4D_wing_Adjoint.jl")

include("./WilsonFermion_2D.jl")
include("./WilsonFermion_2D_wing.jl")





#include("./WilsonFermion_4D_wing_fast.jl")


function Wilson_Dirac_operator(U::Array{<: AbstractGaugefields{NC,Dim},1},x,parameters) where {NC,Dim}
    xtype = typeof(x)
    num = check_parameters(parameters,"numtempvec",7)
    #num = 7
    _temporary_fermi = Array{xtype,1}(undef,num)

    @assert haskey(parameters,"κ") "parameters should have the keyword κ"
    κ = parameters["κ"]
    if Dim == 4
        boundarycondition = check_parameters(parameters,"boundarycondition",[1,1,1,-1])
    elseif Dim == 2
        boundarycondition = check_parameters(parameters,"boundarycondition",[1,-1])
    else
        error("Dim should be 2 or 4!")
    end

    #boundarycondition = check_parameters(parameters,"boundarycondition",[1,1,1,-1])

    r = check_parameters(parameters,"r",1.0)

    if Dim==4
        γ,rplusγ,rminusγ = mk_gamma(r)
        hopp = zeros(ComplexF64,4)
        hopm = zeros(ComplexF64,4)
        hopp .= κ
        hopm .= κ
    elseif Dim == 2
        γ,rplusγ,rminusγ = mk_sigma(r)
        hopp = zeros(ComplexF64,2)
        hopm = zeros(ComplexF64,2)
        hopp .= κ
        hopm .= κ
    end


    
    for i=1:num
        _temporary_fermi[i] = similar(x)
    end

    numcg = check_parameters(parameters,"numtempvec_CG",7)
    #numcg = 7
    _temporary_fermion_forCG= Array{xtype,1}(undef,numcg)
    for i=1:numcg
        _temporary_fermion_forCG[i] = similar(x)
    end


    eps_CG = check_parameters(parameters,"eps_CG",default_eps_CG)
    #println("eps_CG = ",eps_CG)
    MaxCGstep = check_parameters(parameters,"MaxCGstep",default_MaxCGstep)

    verbose_level = check_parameters(parameters,"verbose_level",2)
    verbose_print = Verbose_print(verbose_level)

    method_CG = check_parameters(parameters,"method_CG","bicg")


    for i=1:num
        _temporary_fermi[i] = similar(x)
    end

    hasclover = check_parameters(parameters,"hasclover",false)
    if hasclover
        cSW = r = check_parameters(parameters,"cSW",1.0)
        cloverterm = WilsonClover(cSW)
        #error("notsupported")
    else
        cloverterm = nothing
    end


    return Wilson_Dirac_operator{Dim,eltype(U),xtype}(U,boundarycondition,_temporary_fermi,
        γ,
        rplusγ,
        rminusγ,
        κ,
        r,
        hopp,
        hopm,
        eps_CG,MaxCGstep,verbose_level,
        method_CG,
        cloverterm,
        verbose_print,
        _temporary_fermion_forCG
        )
end

function (D::Wilson_Dirac_operator{Dim,T,fermion})(U) where {Dim,T,fermion}
    return Wilson_Dirac_operator{Dim,T,fermion}(U,D.boundarycondition,D._temporary_fermi,
        D.γ,
        D.rplusγ,
        D.rminusγ,
        D.κ,
        D.r,
        D.hopp,
        D.hopm,
        D.eps_CG,D.MaxCGstep,D.verbose_level,
        D.method_CG,
        D.cloverterm,
        D.verbose_print,
        D._temporary_fermion_forCG
        )
end



struct Adjoint_Wilson_operator{T} <: Adjoint_Dirac_operator
    parent::T
end

function Base.adjoint(A::T) where T <: Wilson_Dirac_operator
    Adjoint_Wilson_operator{typeof(A)}(A)
end

struct Adjoint_Wilson_operator_evenodd{T} <: Adjoint_Dirac_operator
    parent::T
end

function Base.adjoint(A::T) where T <: Wilson_Dirac_operator_evenodd
    Adjoint_Wilson_operator_evenodd{typeof(A)}(A)
end

function Initialize_WilsonFermion(u::AbstractGaugefields{NC,Dim}) where {NC,Dim}
    _,_,NN... = size(u)
    return Initialize_WilsonFermion(NC,NN...) 
end

function Initialize_4DWilsonFermion(u::AbstractGaugefields{NC,Dim}) where {NC,Dim}
    _,_,NN... = size(u)
    return WilsonFermion_4D_wing{NC}(NN...)
end

function Initialize_WilsonFermion(NC,NN...) 
    Dim = length(NN)
    if Dim == 4
        fermion = WilsonFermion_4D_wing{NC}(NN...)
        #fermion = WilsonFermion_4D_wing(NC,NN...)
    elseif Dim == 2
        fermion = WilsonFermion_2D_wing{NC}(NN...)
    else
        error("Dimension $Dim is not supported")
    end
    return fermion
end

using InteractiveUtils

function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: Wilson_Dirac_operator, T3 <:AbstractFermionfields}
    
    #@time Wx!(y,A.U,x,A,A._temporary_fermi) 
    Wx!(y,A.U,x,A) 
    if A.cloverterm != nothing
        Wclover!(y,A.U,x,A)
        error("not implemented!")
    end
    #error("w")
    #error("LinearAlgebra.mul!(y,A,x) is not implemented in type y:$(typeof(y)),A:$(typeof(A)) and x:$(typeof(x))")
end

function LinearAlgebra.mul!(y::T1,A::Wilson_Dirac_operator_evenodd{Dim,T,fermion},x::T3) where {T1 <:AbstractFermionfields,T, Dim,fermion, T3 <:AbstractFermionfields}
    WWx!(y,A.parent.U,x,A.parent) 
end

function LinearAlgebra.mul!(y::T1,A::Adjoint_Wilson_operator_evenodd,x::T3) where {T1 <:AbstractFermionfields, T3 <:AbstractFermionfields}
    WWdagx!(y,A.parent.parent.U,x,A.parent.parent) 
end

function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: Adjoint_Wilson_operator, T3 <:  AbstractFermionfields}
    #error("LinearAlgebra.mul!(y,A,x) is not implemented in type y:$(typeof(y)),A:$(typeof(A)) and x:$(typeof(x))")
    Wdagx!(y,A.parent.U,x,A.parent) 
    #error("LinearAlgebra.mul!(y,A,x) is not implemented in type y:$(typeof(y)),A:$(typeof(A)) and x:$(typeof(x))")

    return
end



"""
mk_gamma()
c----------------------------------------------------------------------c
c     Make gamma matrix
c----------------------------------------------------------------------c
C     THE CONVENTION OF THE GAMMA MATRIX HERE
C     ( EUCLIDEAN CHIRAL REPRESENTATION )
C
C               (       -i )              (       -1 )
C     GAMMA1 =  (     -i   )     GAMMA2 = (     +1   )
C               (   +i     )              (   +1     )
C               ( +i       )              ( -1       )
C
C               (     -i   )              (     -1   )
C     GAMMA3 =  (       +i )     GAMMA4 = (       -1 )
C               ( +i       )              ( -1       )
C               (   -i     )              (   -1     )
C
C               ( -1       )
C     GAMMA5 =  (   -1     )
C               (     +1   )
C               (       +1 )
C
C     ( GAMMA_MU, GAMMA_NU ) = 2*DEL_MU,NU   FOR MU,NU=1,2,3,4   
c----------------------------------------------------------------------c
"""
function mk_gamma(r)
    g0 = zeros(ComplexF64,4,4)
    g1 = zero(g0)
    g2 = zero(g1)
    g3 = zero(g1)
    g4 = zero(g1)
    g5 = zero(g1)
    gamma = zeros(ComplexF64,4,4,5)
    rpg = zero(gamma)
    rmg = zero(gamma)


    g0[1,1]=1.0; g0[1,2]=0.0; g0[1,3]=0.0; g0[1,4]=0.0
    g0[2,1]=0.0; g0[2,2]=1.0; g0[2,3]=0.0; g0[2,4]=0.0
    g0[3,1]=0.0; g0[3,2]=0.0; g0[3,3]=1.0; g0[3,4]=0.0
    g0[4,1]=0.0; g0[4,2]=0.0; g0[4,3]=0.0; g0[4,4]=1.0

    g1[1,1]=0.0; g1[1,2]=0.0; g1[1,3]=0.0; g1[1,4]=-im
    g1[2,1]=0.0; g1[2,2]=0.0; g1[2,3]=-im;  g1[2,4]=0.0
    g1[3,1]=0.0; g1[3,2]=+im;  g1[3,3]=0.0; g1[3,4]=0.0
    g1[4,1]=+im;  g1[4,2]=0.0; g1[4,3]=0.0; g1[4,4]=0.0

    g2[1,1]=0.0; g2[1,2]=0.0; g2[1,3]=0.0; g2[1,4]=-1.0
    g2[2,1]=0.0; g2[2,2]=0.0; g2[2,3]=1.0; g2[2,4]=0.0
    g2[3,1]=0.0; g2[3,2]=1.0; g2[3,3]=0.0; g2[3,4]=0.0
    g2[4,1]=-1.0;g2[4,2]=0.0; g2[4,3]=0.0; g2[4,4]=0.0

    g3[1,1]=0.0; g3[1,2]=0.0; g3[1,3]=-im;  g3[1,4]=0.0
    g3[2,1]=0.0; g3[2,2]=0.0; g3[2,3]=0.0; g3[2,4]=+im
    g3[3,1]=+im;  g3[3,2]=0.0; g3[3,3]=0.0; g3[3,4]=0.0
    g3[4,1]=0.0; g3[4,2]=-im;  g3[4,3]=0.0; g3[4,4]=0.0

    g4[1,1]=0.0; g4[1,2]=0.0; g4[1,3]=-1.0;g4[1,4]=0.0
    g4[2,1]=0.0; g4[2,2]=0.0; g4[2,3]=0.0; g4[2,4]=-1.0
    g4[3,1]=-1.0;g4[3,2]=0.0; g4[3,3]=0.0; g4[3,4]=0.0
    g4[4,1]=0.0; g4[4,2]=-1.0;g4[4,3]=0.0; g4[4,4]=0.0

    g5[1,1]=-1.0;g5[1,2]=0.0; g5[1,3]=0.0; g5[1,4]=0.0
    g5[2,1]=0.0; g5[2,2]=-1.0;g5[2,3]=0.0; g5[2,4]=0.0
    g5[3,1]=0.0; g5[3,2]=0.0; g5[3,3]=1.0; g5[3,4]=0.0
    g5[4,1]=0.0; g5[4,2]=0.0; g5[4,3]=0.0; g5[4,4]=1.0

    gamma[:,:,1] = g1[:,:]
    gamma[:,:,2] = g2[:,:]
    gamma[:,:,3] = g3[:,:]
    gamma[:,:,4] = g4[:,:]
    gamma[:,:,5] = g5[:,:]

    for mu=1:4
        for j=1:4
            for i=1:4
                rpg[i,j,mu] = r*g0[i,j] + gamma[i,j,mu]
                rmg[i,j,mu] = r*g0[i,j] - gamma[i,j,mu]
            end
        end
    end 

    return gamma,rpg,rmg


end

function mk_sigma(r)
    g0 = zeros(ComplexF64,2,2)
    g1 = zero(g0)
    g2 = zero(g1)
    g3 = zero(g1)

    gamma = zeros(ComplexF64,2,2,3)
    rpg = zero(gamma)
    rmg = zero(gamma)


    g0[1,1]=1.0; g0[1,2]=0.0 
    g0[2,1]=0.0; g0[2,2]=1.0

    g1[1,1]=0.0; g1[1,2]=1.0
    g1[2,1]=1.0; g1[2,2]=0.0


    g2[1,1]=0.0; g2[1,2]=-im
    g2[2,1]=+im; g2[2,2]=0.0

    g3[1,1]=1.0; g3[1,2]=0.0
    g3[2,1]=0.0; g3[2,2]=-1.0


    gamma[:,:,1] = g1[:,:]
    gamma[:,:,2] = g2[:,:]
    gamma[:,:,3] = g3[:,:]

    for mu=1:2
        for j=1:2
            for i=1:2
                rpg[i,j,mu] = r*g0[i,j] + gamma[i,j,mu]
                rmg[i,j,mu] = r*g0[i,j] - gamma[i,j,mu]
            end
        end
    end 

    return gamma,rpg,rmg

end


gtmp1,gtmp2,gtmp3 = mk_gamma(1)
const γ_all = gtmp1 
const γ5 = γ_all[:,:,5]

const rplusγ1 = gtmp2
const rminusγ1 = gtmp3



include("./WilsontypeFermion.jl")

function Wx!(xout::T,U::Array{G,1},x::T,A,Dim)  where  {T,G <: AbstractGaugefields}
    #temps::Array{T,1},boundarycondition) where  {T <: WilsonFermion_4D,G <: AbstractGaugefields}
    temp = A._temporary_fermi[4]#temps[4]
    temp1 = A._temporary_fermi[1] #temps[1]
    temp2 = A._temporary_fermi[2] #temps[2]

    #temp = temps[4]
    #temp1 = temps[1]cc
    #temp2 = temps[2]

    clear_fermion!(temp)
    #set_wing_fermion!(x)
    for ν=1:Dim
        
        xplus = shift_fermion(x,ν)
        #println(xplus)
        

        mul!(temp1,U[ν],xplus)
       

        #fermion_shift!(temp1,U,ν,x)

        #... Dirac multiplication

        mul!(temp1,view(A.rminusγ,:,:,ν))

        

        xminus = shift_fermion(x,-ν)
        Uminus = shift_U(U[ν],-ν)


        mul!(temp2,Uminus',xminus)
     
        #
        #fermion_shift!(temp2,U,-ν,x)
        #mul!(temp2,view(x.rplusγ,:,:,ν),temp2)
        mul!(temp2,view(A.rplusγ,:,:,ν))

        add_fermion!(temp,A.hopp[ν],temp1,A.hopm[ν],temp2)

    end

    clear_fermion!(xout)
    add_fermion!(xout,1,x,-1,temp)

    set_wing_fermion!(xout,A.boundarycondition)

    #display(xout)
    #    exit()
    return
end


function Dx!(xout::T1,U::Array{G,1},x::T2,A,Dim) where  {T1,T2,G <: AbstractGaugefields}
    temp = A._temporary_fermi[4]#temps[4]
    temp1 = A._temporary_fermi[1] #temps[1]
    temp2 = A._temporary_fermi[2] #temps[2]

    clear_fermion!(temp)
    #clear!(temp1)
    #clear!(temp2)
    set_wing_fermion!(x)
    for ν=1:Dim
        xplus = shift_fermion(x,ν)
        mul!(temp1,U[ν],xplus)
        #... Dirac multiplication
        mul!(temp1,view(A.rminusγ,:,:,ν),temp1)
        
        #
        xminus = shift_fermion(x,-ν)
        Uminus = shift_U(U[ν],-ν)
        mul!(temp2,Uminus',xminus)

        mul!(temp2,view(A.rplusγ,:,:,ν),temp2)
        add_fermion!(temp,0.5,temp1,0.5,temp2)
        
    end

    clear_fermion!(xout)
    add_fermion!(xout,1/(2*A.κ),x,-1,temp)

    #display(xout)
    #    exit()
    return
end

function Ddagx!(xout::T1,U::Array{G,1},x::T2,A,Dim) where  {T1,T2,G <: AbstractGaugefields}
    temp = A._temporary_fermi[4]#temps[4]
    temp1 = A._temporary_fermi[1] #temps[1]
    temp2 = A._temporary_fermi[2] #temps[2]

    clear_fermion!(temp)
    #clear!(temp1)
    #clear!(temp2)
    set_wing_fermion!(x)
    for ν=1:Dim
        xplus = shift_fermion(x,ν)
        mul!(temp1,U[ν],xplus)
        #... Dirac multiplication
        mul!(temp1,view(A.rplusγ,:,:,ν),temp1)
        
        #
        xminus = shift_fermion(x,-ν)
        Uminus = shift_U(U[ν],-ν)
        mul!(temp2,Uminus',xminus)

        mul!(temp2,view(A.rminusγ,:,:,ν),temp2)
        add_fermion!(temp,0.5,temp1,0.5,temp2)
        
    end

    clear_fermion!(xout)
    add_fermion!(xout,1/(2*A.κ),x,-1,temp)

    #display(xout)
    #    exit()
    return
end

function Tx!(xout::T,U::Array{G,1},x::T,A,Dim)  where  {T,G <: AbstractGaugefields} # Tx, W = (1 - T)x
    #temps::Array{T,1},boundarycondition) where  {T <: WilsonFermion_4D,G <: AbstractGaugefields}
    temp = A._temporary_fermi[4]#temps[4]
    temp1 = A._temporary_fermi[1] #temps[1]
    temp2 = A._temporary_fermi[2] #temps[2]

    #temp = temps[4]
    #temp1 = temps[1]
    #temp2 = temps[2]

    clear_fermion!(temp)
    #set_wing_fermion!(x)
    for ν=1:Dim
        
        xplus = shift_fermion(x,ν)
        #println(xplus)
        

        mul!(temp1,U[ν],xplus)
       

        #fermion_shift!(temp1,U,ν,x)

        #... Dirac multiplication

        mul!(temp1,view(A.rminusγ,:,:,ν))

        

        xminus = shift_fermion(x,-ν)
        Uminus = shift_U(U[ν],-ν)


        mul!(temp2,Uminus',xminus)
     
        #
        #fermion_shift!(temp2,U,-ν,x)
        #mul!(temp2,view(x.rplusγ,:,:,ν),temp2)
        mul!(temp2,view(A.rplusγ,:,:,ν))

        add_fermion!(temp,A.hopp[ν],temp1,A.hopm[ν],temp2)

    end

    clear_fermion!(xout)
    add_fermion!(xout,0,x,1,temp)

    set_wing_fermion!(xout,A.boundarycondition)

    #display(xout)
    #    exit()
    return
end

function Wdagx!(xout::T,U::Array{G,1},
    x::T,A,Dim) where  {T,G <: AbstractGaugefields}
    #,temps::Array{T,1},boundarycondition) where  {T <: WilsonFermion_4D,G <: AbstractGaugefields}
    temp = A._temporary_fermi[4] #temps[4]
    temp1 = A._temporary_fermi[1] #temps[1]
    temp2 = A._temporary_fermi[2] #temps[2]

    clear_fermion!(temp)
    #set_wing_fermion!(x)
    for ν=1:Dim
        xplus = shift_fermion(x,ν)
        mul!(temp1,U[ν],xplus)

        #fermion_shift!(temp1,U,ν,x)

        #... Dirac multiplication
        #mul!(temp1,view(x.rminusγ,:,:,ν),temp1)
        mul!(temp1,view(A.rplusγ,:,:,ν))
        
        
        #
        xminus = shift_fermion(x,-ν)
        Uminus = shift_U(U[ν],-ν)

        mul!(temp2,Uminus',xminus)
        #fermion_shift!(temp2,U,-ν,x)
        #mul!(temp2,view(x.rminusγ,:,:,ν),temp2)
        mul!(temp2,view(A.rminusγ,:,:,ν))


        add_fermion!(temp,A.hopp[ν],temp1,A.hopm[ν],temp2)
        
        
        
    end

    clear_fermion!(xout)
    add_fermion!(xout,1,x,-1,temp)
    set_wing_fermion!(xout,A.boundarycondition)

    #display(xout)
    #    exit()
    return
end

