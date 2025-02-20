import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Settings } from 'lucide-react';
import toast from 'react-hot-toast';

interface BatchCosts {
  can_cost_per_unit: number | '';
  tray_cost_per_unit: number | '';
  paktech_cost_per_unit: number | '';
  can_end_cost_per_unit: number | '';
  storage_cost_per_unit: number | '';
  tolling_cost_per_gallon: number | '';
}

interface BatchSettingsProps {
  onSettingsUpdate?: () => void;
}

interface BatchSize {
  size_gallons: number;
  cans_per_batch: number;
  can_size_id?: string;
}

interface CanSize {
  id: string;
  size_oz: number;
  name: string;
}

interface FreightCost {
  supplier_id: string;
  cost: number;
}

export function BatchSettings({ onSettingsUpdate }: BatchSettingsProps) {
  const [batchCosts, setBatchCosts] = useState<BatchCosts>({
    can_cost_per_unit: '',
    tray_cost_per_unit: '',
    paktech_cost_per_unit: '',
    can_end_cost_per_unit: '',
    storage_cost_per_unit: '',
    tolling_cost_per_gallon: '',
  });
  const [batchSize, setBatchSize] = useState<BatchSize>({
    size_gallons: 500,
    cans_per_batch: 4000,
    can_size_id: '',
  });
  const [canSizes, setCanSizes] = useState<CanSize[]>([]);
  const [freightCosts, setFreightCosts] = useState<FreightCost[]>([]);
  const [suppliers, setSuppliers] = useState<
    Array<{ id: string; name: string }>
  >([]);
  const [loading, setLoading] = useState(true);
  const [costSummary, setCostSummary] = useState({
    totalPackagingCostPerUnit: 0,
    totalTollingCostPerBatch: 0,
    totalPackagingCostPerBatch: 0
  });
  const [showPerCan, setShowPerCan] = useState(true);

  useEffect(() => {
    loadSettings();
  }, []);

  useEffect(() => {
    // Calculate and update cost summary whenever relevant values change
    const totalPackagingCostPerUnit = (
      (Number(batchCosts.can_cost_per_unit) || 0) +
      (Number(batchCosts.can_end_cost_per_unit) || 0) +
      (Number(batchCosts.tray_cost_per_unit) || 0) +
      (Number(batchCosts.paktech_cost_per_unit) || 0) +
      (Number(batchCosts.storage_cost_per_unit) || 0)
    );

    const totalTollingCostPerBatch = 
      (Number(batchCosts.tolling_cost_per_gallon) || 0) * (batchSize.size_gallons || 0);

    const totalPackagingCostPerBatch = totalPackagingCostPerUnit * batchSize.cans_per_batch;

    setCostSummary({
      totalPackagingCostPerUnit,
      totalTollingCostPerBatch,
      totalPackagingCostPerBatch
    });
  }, [batchCosts, batchSize.size_gallons]);

  async function loadSettings() {
    try {
      // Load can sizes
      const { data: canSizesData, error: canSizesError } = await supabase
        .from('can_sizes')
        .select('*')
        .order('size_oz');

      if (canSizesError) throw canSizesError;
      if (canSizesData) {
        setCanSizes(canSizesData);
      }

      // Load batch costs
      const { data: costsData, error: costsError } = await supabase
        .from('batch_costs')
        .select('*')
        .limit(1)
        .single();

      if (costsError && costsError.code !== 'PGRST116') {
        throw costsError;
      }

      if (costsData) {
        setBatchCosts({
          can_cost_per_unit: costsData.can_cost_per_unit ?? '',
          tray_cost_per_unit: costsData.tray_cost_per_unit ?? '',
          paktech_cost_per_unit: costsData.paktech_cost_per_unit ?? '',
          can_end_cost_per_unit: costsData.can_end_cost_per_unit ?? '',
          storage_cost_per_unit: costsData.storage_cost_per_unit ?? '',
          tolling_cost_per_gallon: costsData.tolling_cost_per_gallon ?? '',
        });
      }

      // Load batch size
      const { data: sizeData, error: sizeError } = await supabase
        .from('batch_sizes')
        .select('*')
        .limit(1)
        .single();

      if (sizeError && sizeError.code !== 'PGRST116') {
        throw sizeError;
      }

      if (sizeData) {
        setBatchSize(sizeData);
      }

      // Load suppliers
      const { data: suppliersData } = await supabase
        .from('suppliers')
        .select('id, name');

      if (suppliersData) {
        setSuppliers(suppliersData);

        // Load freight costs
        const { data: freightData } = await supabase
          .from('freight_costs')
          .select('*');

        if (freightData) {
          setFreightCosts(freightData);
        }
      }
    } catch (error) {
      console.error('Error loading settings:', error);
      toast.error('Failed to load settings');
    } finally {
      setLoading(false);
    }
  }

  const calculateCansPerBatch = (gallons: number, canSizeOz: number) => {
    const OUNCES_PER_GALLON = 128;
    const totalOunces = gallons * OUNCES_PER_GALLON;
    return Math.floor(totalOunces / canSizeOz);
  };

  const handleBatchSizeChange = (gallons: number) => {
    // Ensure gallons is a valid number
    const validGallons = isNaN(gallons) ? 0 : Math.max(0, gallons);
    
    const selectedCanSize = canSizes.find(
      (cs) => cs.id === batchSize.can_size_id
    );
    
    setBatchSize((prev) => ({
      ...prev,
      size_gallons: validGallons,
      cans_per_batch: selectedCanSize
        ? calculateCansPerBatch(validGallons, selectedCanSize.size_oz)
        : prev.cans_per_batch,
    }));
  };

  const handleCanSizeChange = (canSizeId: string) => {
    const selectedCanSize = canSizes.find((cs) => cs.id === canSizeId);
    
    setBatchSize((prev) => ({
      ...prev,
      can_size_id: canSizeId,
      cans_per_batch: selectedCanSize
        ? calculateCansPerBatch(prev.size_gallons, selectedCanSize.size_oz)
        : prev.cans_per_batch,
    }));
  };

  const handleSave = async () => {
    try {
      // First, check if a batch costs record exists for the current user
      const { data: existingCosts, error: fetchError } = await supabase
        .from('batch_costs')
        .select('id')
        .limit(1)
        .single();

      if (fetchError && fetchError.code !== 'PGRST116') throw fetchError;

      // Prepare validated batch costs
      const validatedBatchCosts = {
        can_cost_per_unit: Number(batchCosts.can_cost_per_unit) || 0,
        can_end_cost_per_unit: Number(batchCosts.can_end_cost_per_unit) || 0,
        tray_cost_per_unit: Number(batchCosts.tray_cost_per_unit) || 0,
        paktech_cost_per_unit: Number(batchCosts.paktech_cost_per_unit) || 0,
        storage_cost_per_unit: Number(batchCosts.storage_cost_per_unit) || 0,
        tolling_cost_per_gallon: Number(batchCosts.tolling_cost_per_gallon) || 0,
      };

      let costsUpsertError;
      if (existingCosts?.id) {
        // Update existing record
        const { error } = await supabase
          .from('batch_costs')
          .update(validatedBatchCosts)
          .eq('id', existingCosts.id);
        costsUpsertError = error;
      } else {
        // Insert new record
        const { error } = await supabase
          .from('batch_costs')
          .insert([validatedBatchCosts]);
        costsUpsertError = error;
      }

      if (costsUpsertError) throw costsUpsertError;

      // Validate batch size
      const validatedBatchSize = {
        ...batchSize,
        size_gallons: batchSize.size_gallons || 0,
        cans_per_batch: batchSize.cans_per_batch || 0
      };

      // Update batch size
      const { error: sizeUpsertError } = await supabase
        .from('batch_sizes')
        .upsert([validatedBatchSize]);

      if (sizeUpsertError) throw sizeUpsertError;

      // Validate freight costs
      const validatedFreightCosts = freightCosts.map(fc => ({
        ...fc,
        cost: fc.cost || 0
      }));

      // Update freight costs
      const { error: freightError } = await supabase
        .from('freight_costs')
        .upsert(validatedFreightCosts);

      if (freightError) throw freightError;

      toast.success('Settings saved successfully');
      onSettingsUpdate?.();
    } catch (error) {
      console.error('Error saving settings:', error);
      toast.error('Failed to save settings');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <Settings className="animate-spin h-8 w-8" />
      </div>
    );
  }

  return (
    <div className="space-y-6 bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg p-6">
      <h2 className="text-lg font-semibold text-gray-900">Batch Settings</h2>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="col-span-2 flex justify-end">
          <button
            onClick={() => setShowPerCan(!showPerCan)}
            className="inline-flex items-center px-3 py-1.5 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            Show {showPerCan ? 'Per Batch' : 'Per Can'} Costs
          </button>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Batch Size (Gallons)
          </label>
          <input
            type="number"
            value={batchSize.size_gallons}
            onChange={(e) => handleBatchSizeChange(parseFloat(e.target.value))}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Can Size
          </label>
          <select
            value={batchSize.can_size_id || ''}
            onChange={(e) => handleCanSizeChange(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          >
            <option value="">Select a can size</option>
            {canSizes.map((size) => (
              <option key={size.id} value={size.id}>
                {size.name} ({size.size_oz}oz)
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Cans per Batch
          </label>
          <div className="mt-1 block w-full rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-gray-700 sm:text-sm">
            {batchSize.cans_per_batch.toLocaleString()}
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Can Body Cost (per unit)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.can_cost_per_unit === '' ? '' : Number(batchCosts.can_cost_per_unit)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                can_cost_per_unit: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Can End Cost (per unit)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.can_end_cost_per_unit === '' ? '' : Number(batchCosts.can_end_cost_per_unit)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                can_end_cost_per_unit: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Tray Cost (per unit)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.tray_cost_per_unit === '' ? '' : Number(batchCosts.tray_cost_per_unit)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                tray_cost_per_unit: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            PakTech Cost (per unit)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.paktech_cost_per_unit === '' ? '' : Number(batchCosts.paktech_cost_per_unit)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                paktech_cost_per_unit: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Storage Cost (per unit)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.storage_cost_per_unit === '' ? '' : Number(batchCosts.storage_cost_per_unit)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                storage_cost_per_unit: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Tolling Cost (per gallon)
          </label>
          <input
            type="number"
            step="0.01"
            value={batchCosts.tolling_cost_per_gallon === '' ? '' : Number(batchCosts.tolling_cost_per_gallon)}
            onChange={(e) =>
              setBatchCosts((prev) => ({
                ...prev,
                tolling_cost_per_gallon: e.target.value === '' ? '' : Number(e.target.value),
              }))
            }
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div className="col-span-2">
          <div className="bg-gray-50 p-4 rounded-lg space-y-4">
            <h4 className="text-sm font-medium text-gray-900 mb-2">Cost Summary</h4>
            <div className="grid grid-cols-2 gap-8">
              <div className="space-y-2">
                <h5 className="font-medium text-sm text-gray-700">Per Can Costs</h5>
                <div className="bg-white p-3 rounded border border-gray-200 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-blue-600">Packaging Cost:</span>
                    <span>${costSummary.totalPackagingCostPerUnit.toFixed(4)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-purple-600">Tolling Cost:</span>
                    <span>${(costSummary.totalTollingCostPerBatch / batchSize.cans_per_batch).toFixed(4)}</span>
                  </div>
                </div>
              </div>
              <div className="space-y-2">
                <h5 className="font-medium text-sm text-gray-700">Per Batch Costs</h5>
                <div className="bg-white p-3 rounded border border-gray-200 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-blue-600">Total Packaging:</span>
                    <span>${costSummary.totalPackagingCostPerBatch.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-purple-600">Total Tolling:</span>
                    <span>${costSummary.totalTollingCostPerBatch.toFixed(2)}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <h3 className="text-md font-medium text-gray-900">
          Freight Costs by Supplier
        </h3>
        {suppliers.map((supplier) => (
          <div key={supplier.id} className="flex items-center gap-4">
            <span className="text-sm text-gray-700 min-w-[200px]">
              {supplier.name}
            </span>
            <input
              type="number"
              step="0.01"
              value={
                freightCosts.find((fc) => fc.supplier_id === supplier.id)
                  ?.cost || 0
              }
              onChange={(e) => {
                const newCost = parseFloat(e.target.value);
                setFreightCosts((prev) => {
                  const existing = prev.find(
                    (fc) => fc.supplier_id === supplier.id
                  );
                  if (existing) {
                    return prev.map((fc) =>
                      fc.supplier_id === supplier.id
                        ? { ...fc, cost: newCost }
                        : fc
                    );
                  }
                  return [...prev, { supplier_id: supplier.id, cost: newCost }];
                });
              }}
              className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>
        ))}
      </div>

      <div className="flex justify-end">
        <button
          onClick={handleSave}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Save Settings
        </button>
      </div>
    </div>
  );
}