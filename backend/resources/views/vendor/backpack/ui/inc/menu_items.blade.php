{{-- This file is used for menu items by any Backpack v6 theme --}}
<li class="nav-item"><a class="nav-link" href="{{ backpack_url('dashboard') }}"><i class="la la-home nav-icon"></i> {{ trans('backpack::base.dashboard') }}</a></li>

<x-backpack::menu-item title="Categorias" icon="la la-question" :link="backpack_url('categoria')" />
<x-backpack::menu-item title="Productos" icon="la la-question" :link="backpack_url('producto')" />
<x-backpack::menu-item title="Users" icon="la la-question" :link="backpack_url('user')" />
<x-backpack::menu-item title="Vehiculos" icon="la la-question" :link="backpack_url('vehiculo')" />
<x-backpack::menu-item title="Orden trabajos" icon="la la-question" :link="backpack_url('orden-trabajo')" />
<x-backpack::menu-item title="Transaccion inventarios" icon="la la-question" :link="backpack_url('transaccion-inventario')" />