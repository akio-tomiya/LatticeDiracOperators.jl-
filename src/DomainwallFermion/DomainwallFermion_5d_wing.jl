"""
Struct for DomainwallFermion
"""
struct DomainwallFermion_5D_wing{NC,WilsonFermion} <: AbstractFermionfields_5D{NC}
    w::Array{WilsonFermion,1}
    NC::Int64
    NX::Int64
    NY::Int64
    NZ::Int64
    NT::Int64
    L5::Int64   
    Dirac_operator::String
    NWilson::Int64

    function DomainwallFermion_5D_wing(L5,NC::T,NX::T,NY::T,NZ::T,NT::T) where T<: Integer
        x = WilsonFermion_4D_wing(NC,NX,NY,NZ,NT)
        xtype = typeof(x)
        w = Array{xtype,1}(undef,L5)
        w[1] = x
        for i=2:L5
            w[i] = similar(x)
        end
        #println(w[2][1,1,1,1,1,1])
        NWilson = length(x)
        Dirac_operator = "Domainwall"
        return new{NC,xtype}(w,NC,NX,NY,NZ,NT,L5,Dirac_operator,NWilson)
    end

end




function Base.similar(x::DomainwallFermion_5D_wing{NC,WilsonFermion} ) where {NC,WilsonFermion}
    return DomainwallFermion_5D_wing(x.L5,NC,x.NX,x.NY,x.NZ,x.NT)
end

function D5DWx!(xout::DomainwallFermion_5D_wing{NC,WilsonFermion} ,U::Array{G,1},
    x::DomainwallFermion_5D_wing{NC,WilsonFermion} ,m,A,L5) where  {NC,WilsonFermion,G <: AbstractGaugefields}

    #temp = temps[4]
    #temp1 = temps[1]
    #temp2 = temps[2]
    clear_fermion!(xout)
    ratio = 1
    #ratio = xout.L5/L5

    for i5=1:L5   
        j5=i5
        D4x!(xout.w[i5],U,x.w[j5],A,4) #Dw*x
        #Dx!(xout.w[i5],U,x.w[j5],A) #Dw*x
        #Wx!(xout.w[i5],U,x.w[j5],temps) #Dw*x
        #1/(2*A.κ)
        massfactor = -(1/(2*A.κ) + 1)
        set_wing_fermion!(xout.w[i5])
        #add!(ratio,xout.w[i5],ratio,x.w[j5]) #D = x + Ddagw*x
        add!(ratio,xout.w[i5],ratio*massfactor,x.w[j5]) #D = x + Dw*x
        set_wing_fermion!(xout.w[i5])  

    
        j5=i5+1
        if 1 <= j5 <= L5
            #-P_- -> - P_+ :gamma_5 of LTK definition
            if L5 != 2
                #mul_1minusγ5x_add!(xout.w[i5],x.w[j5],-1*ratio) 
                mul_1plusγ5x_add!(xout.w[i5],x.w[j5],ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

        j5=i5-1
        if 1 <= j5 <= L5
            #-P_+ -> - P_- :gamma_5 of LTK definition
            if L5 != 2
                #mul_1plusγ5x_add!(xout.w[i5],x.w[j5],-1*ratio) 
                mul_1minusγ5x_add!(xout.w[i5],x.w[j5],ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

        if L5 != 1
            if i5==1
                j5 = L5
                #mul_1plusγ5x_add!(xout.w[i5],x.w[j5],m*ratio) 
                mul_1minusγ5x_add!(xout.w[i5],x.w[j5],-m*ratio) 
                set_wing_fermion!(xout.w[i5])  
            end

            if i5== L5
                j5 = 1
                #mul_1minusγ5x_add!(xout.w[i5],x.w[j5],m*ratio) 
                mul_1plusγ5x_add!(xout.w[i5],x.w[j5],-m*ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

    end  
    set_wing_fermion!(xout)   

    if L5 != xout.L5
        for i5=L5+1:xout.L5
            axpy!(1,x.w[i5],xout.w[i5])
        end
    end

    return
end

function D5DWdagx!(xout::DomainwallFermion_5D_wing{NC,WilsonFermion} ,U::Array{G,1},
    x::DomainwallFermion_5D_wing{NC,WilsonFermion} ,m,A,L5) where  {NC,WilsonFermion,G <: AbstractGaugefields}

    #temp = temps[4]
    #temp1 = temps[1]
    #temp2 = temps[2]
    clear_fermion!(xout)
    ratio = 1
    #ratio = xout.L5/L5

    for i5=1:L5   
        j5=i5
        #Ddagx!(xout.w[i5],U,x.w[j5],A) #Ddagw*x
        D4dagx!(xout.w[i5],U,x.w[j5],A,4) #Dw*x
        #Wx!(xout.w[i5],U,x.w[j5],temps) #Dw*x
        #1/(2*A.κ)
        massfactor = -(1/(2*A.κ) + 1)
        #println(massfactor)

        #Wdagx!(xout.w[i5],U,x.w[j5],temps) #Ddagw*x
        set_wing_fermion!(xout.w[i5])
        add!(ratio,xout.w[i5],ratio*massfactor,x.w[j5]) #D = x + Dw*x
        #add!(ratio,xout.w[i5],ratio,x.w[j5]) #D = x + Ddagw*x
        set_wing_fermion!(xout.w[i5])  

    
        j5=i5+1
        if 1 <= j5 <= L5
            #-P_-
            if L5 != 2
                #mul_1plusγ5x_add!(xout.w[i5],x.w[j5],-1*ratio) 
                mul_1minusγ5x_add!(xout.w[i5],x.w[j5],ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

        j5=i5-1
        if 1 <= j5 <= L5
            #-P_+
            if L5 != 2
                #mul_1minusγ5x_add!(xout.w[i5],x.w[j5],-1*ratio) 
                mul_1plusγ5x_add!(xout.w[i5],x.w[j5],ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

        if L5 != 1
            if i5==1
                j5 = L5
                #mul_1minusγ5x_add!(xout.w[i5],x.w[j5],m*ratio) 
                mul_1plusγ5x_add!(xout.w[i5],x.w[j5],-m*ratio) 
                set_wing_fermion!(xout.w[i5])  
            end

            if i5==L5
                j5 = 1
                #mul_1plusγ5x_add!(xout.w[i5],x.w[j5],m*ratio) 
                mul_1minusγ5x_add!(xout.w[i5],x.w[j5],-m*ratio) 
                set_wing_fermion!(xout.w[i5])  
            end
        end

    end  

    if L5 != xout.L5
        for i5=L5+1:xout.L5
            axpy!(1,x.w[i5],xout.w[i5])
        end
    end


    set_wing_fermion!(xout)   

    return
end
