<div
    <?php echo e($attributes
            ->merge([
                'id' => $getId(),
            ], escape: false)
            ->merge($getExtraAttributes(), escape: false)); ?>

>
    <?php echo e($getChildSchema()); ?>

</div>
<?php /**PATH C:\DEV\semanur_app\backend\vendor\filament\schemas\resources\views/components/grid.blade.php ENDPATH**/ ?>