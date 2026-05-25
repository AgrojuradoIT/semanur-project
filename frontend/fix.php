<?php
$f='d:/DEV/semanur_app/frontend/lib/features/fleet/presentation/screens/add_vehicle_screen.dart';
$c=file_get_contents($f);
$c=preg_replace('/(\s*const SizedBox\(height: 30\),\s*_buildSectionTitle\(\'VENCIMIENTOS DOCUMENTALES\'\),)/', "\n              if (_selectedType == 'Volqueta' || _selectedType == 'Camioneta' || _selectedType == 'Moto') ...[$1", $c);
$c=preg_replace('/(_buildDatePicker\(\s*\'Vencimiento Tecnomecánica\',\s*_tecnoDate,\s*\(\) => _selectDate\(context, false\),\s*\),)/', "$1\n              ],", $c);
file_put_contents($f, $c);
