# Load solution procedures
include("functions_heaviside0.jl")

"""
   Solve the sytem of second order ODEs 

   ``M A(t) + C V(t) + K U(t) = F(t)``

   with 

   U(t0) = U0

   V(t0) = V0

   for zero order polynomials multiplied by Heaviside functions
    
   ``f_j = (c_jk0)*H(t-t_jk)``.  

   Loading is informed by using a dictionary  ``load_data = Dict{Int64,Vector{Float64}}()``

   ``load_data[j] = [c_j00; t_j0; ... ; c_j(nk)0; t_j(nk))]``

   were nk is the number of coefficients used to represent the loading at DOF j.
   
   The output is 

   y(t)  => complete solution


"""
function Solve_heaviside0(M::AbstractMatrix{T}, C::AbstractMatrix{T},K::AbstractMatrix{T},
                         U0::AbstractVector{T}, V0::AbstractVector{T}, 
                         load_data::OrderedDict{Int64,Vector{Float64}}; t0=0.0) where T


    # Evaluate F211 
    chol = cholesky(Symmetric(M))
    Kb = chol\K
    Cb = chol\C
    F211 = 0.5*Cb + 0.5*sqrt(Cb^2 - 4*Kb)

    # Pre-evaluate matrices needed to compute the permanente solution
    CbF = Cb - F211
      
    # Evaluate Cb2F (Auxiliary matrix to avoid repeated computation)
    Cb2F = Cb .- 2*F211

    # M01 = CbF^(-1)
    M01 = lu(CbF)

    # M1 = F211^(-1)
    M1 = Array(F211)^(-1) #\ Matrix{eltype(F211)}(I, size(F211)...)
    
    # M001 = (Cb2F)^(-1)
    M001 = lu(Cb2F)

    # m01m1 = M01*M1
    m01m1 = M01\M1
    
    # Pre-process 
    sol_j = Process_heaviside(M,load_data)

    # Evaluate FC (Auxiliary matrix to avoid repeated computation)
    FCb = -CbF
    
    # Evaluate constants C1 and C2 - Appendix A
    C1, C2 = Evaluate_Cs(t0,F211,FCb,Cb2F,U0,V0)

    # Homogeneous solution at t - Equation 49
    yh(t) = y_homo(t,F211,FCb,C1,C2)

    # Permanent solution for a given time
    yp(t) = y_permanent_heaviside0(t,sol_j,load_data,CbF, M1, M001, F211, m01m1)
    
    # Complete response
    y(t) = yp(t) + yh(t)

    # Return complete response, homogeneous and particular
    return y, yh, yp

end
