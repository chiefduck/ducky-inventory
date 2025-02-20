import React from 'react';
import { Download, Printer, Save, ChevronDown, ChevronRight } from 'lucide-react';
import toast from 'react-hot-toast';
import { supabase } from '../lib/supabase';

interface OrderItem {
  id: string;
  name: string;
  row_id?: string;
  supplier: {
    id: string;
    name: string;
  };
  supplier_id: string;
  flavor_id: string;
  batch_requirement: number;
  current_level: number;
  orderQuantity: number;
  pailsNeeded: number;
  totalOrdered: number;
  totalCost: number;
  unit: string;
  moq: number;
  part_number?: string;
}

interface OrderSummaryProps {
  items: OrderItem[];
  freightCosts: Array<{
    supplier_id: string;
    cost: number;
  }>;
  batchCosts: {
    can_cost_per_unit: number;
    tray_cost_per_unit: number;
    paktech_cost_per_unit: number;
    can_end_cost_per_unit: number;
    storage_cost_per_unit: number;
    tolling_cost_per_gallon: number;
  };
  batchSize: {
    size_gallons: number;
    cans_per_batch: number;
  };
}

interface BatchCostSummary {
  totalIngredientCost: number;
  totalPackagingCost: number;
  totalFreightCost: number;
  totalTollingCost: number;
  totalBatchCost: number;
  costPerCan: number;
}

export function OrderSummary({
  items,
  batchCosts,
  freightCosts,
  batchSize,
}: OrderSummaryProps) {
  const [costSummary, setCostSummary] = React.useState<BatchCostSummary | null>(null);
  const [showPerCan, setShowPerCan] = React.useState(true);
  const [expandedRows, setExpandedRows] = React.useState<Set<string>>(new Set());
  const [localItems, setLocalItems] = React.useState<OrderItem[]>([]);
  
  // Update local items when props change
  React.useEffect(() => {
    const updatedItems = items.map(item => ({
      ...item,
      row_id: item.row_id || `${item.id || item.name}-${item.supplier.id}`
    }));
    setLocalItems(updatedItems);
  }, [items]);

  const toggleRow = (rowId: string) => {
    setExpandedRows(prev => {
      const next = new Set(prev);
      if (next.has(rowId)) {
        next.delete(rowId);
      } else {
        next.add(rowId);
      }
      return next;
    });
  };

  React.useEffect(() => {
    calculateBatchCosts();
  }, [localItems, batchCosts, batchSize]);

  const calculateBatchCosts = () => {
    // Ensure all values are numbers and default to 0 if undefined
    const safeNumber = (value: number | undefined): number => 
      typeof value === 'number' && !isNaN(value) && isFinite(value) ? value : 0;

    // Get unique suppliers that have items to order
    const activeSuppliers = new Set(
      localItems
        .filter(item => !item.has_surplus && !item.no_price && item.totalCost > 0)
        .map(item => item.supplier_id)
    );

    // Calculate ingredient costs
    const totalIngredientCost = localItems.reduce(
      (sum, item) => sum + (item.has_surplus || item.no_price ? 0 : safeNumber(item.totalCost)),
      0
    );

    // Calculate total packaging cost per unit
    const totalPackagingCostPerUnit = 
      safeNumber(batchCosts.can_cost_per_unit) +
      safeNumber(batchCosts.can_end_cost_per_unit) +
      safeNumber(batchCosts.tray_cost_per_unit) +
      safeNumber(batchCosts.paktech_cost_per_unit) +
      safeNumber(batchCosts.storage_cost_per_unit);

    // Calculate total packaging cost for the batch
    const totalPackagingCost = safeNumber(batchSize.cans_per_batch) * totalPackagingCostPerUnit;

    // Calculate total freight cost
    const totalFreightCost = Array.from(activeSuppliers).reduce(
      (sum, supplierId) => 
        sum + (freightCosts.find(fc => fc.supplier_id === supplierId)?.cost || 0),
      0
    );

    // Calculate tolling costs
    const totalTollingCost = safeNumber(batchCosts.tolling_cost_per_gallon) * safeNumber(batchSize.size_gallons);

    // Calculate total batch cost
    const totalBatchCost = 
      totalIngredientCost +
      totalPackagingCost +
      totalFreightCost +
      totalTollingCost;

    // Calculate cost per can
    const costPerCan = batchSize.cans_per_batch > 0 ? totalBatchCost / batchSize.cans_per_batch : 0;

    setCostSummary({
      totalIngredientCost,
      totalPackagingCost,
      totalFreightCost,
      totalTollingCost,
      totalBatchCost,
      costPerCan,
    });
  };

  const formatNumber = (num: number) => {
    return (isNaN(num) ? 0 : num).toFixed(2);
  };

  const handleExport = (type: 'csv' | 'pdf') => {
    if (type === 'csv') {
      const headers = [
        'Part #',
        'Ingredient',
        'Supplier',
        'Batch Requirement',
        'Current Inventory',
        'Shortage',
        'Need to Order',
        'Pails Needed',
        'Total',
        'Cost',
        'Cost/Unit',
      ];

      const csvContent = [
        headers.join(','),
        ...localItems.map((item) =>
          [
            item.part_number || 'N/A',
            item.name,
            item.supplier.name,
            `${formatNumber(item.batch_requirement)} ${item.unit}`,
            `${formatNumber(item.current_level)} ${item.unit}`,
            `${formatNumber(item.batch_requirement - item.current_level)} ${
              item.unit
            }`,
            `${formatNumber(item.orderQuantity)} ${item.unit}`,
            item.pailsNeeded,
            `${formatNumber(item.totalOrdered)} ${item.unit}`,
            `$${formatNumber(item.totalCost)}`,
            `$${formatNumber(item.totalCost / item.totalOrdered)}`,
          ].join(',')
        ),
      ].join('\n');

      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'order_summary.csv';
      link.click();
      toast.success('CSV exported successfully');
    } else if (type === 'pdf') {
      // Create PDF content
      const content = `
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; }
              table { width: 100%; border-collapse: collapse; margin: 20px 0; }
              th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
              th { background-color: #f8fafc; }
              .header { margin-bottom: 20px; }
              .summary { margin-top: 20px; }
              .supplier-section { margin-top: 30px; border-top: 2px solid #eee; padding-top: 20px; }
              .supplier-header { font-size: 1.2em; color: #4f46e5; margin-bottom: 10px; }
              .warning { color: #dc2626; font-weight: bold; }
              .success { color: #059669; }
              .note { font-style: italic; color: #6b7280; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1>Order Summary</h1>
              <div>
                <p>Generated: ${new Date().toLocaleString()}</p>
                <p>Batch Size: ${batchSize.size_gallons} gallons</p>
                <p>Total Cans: ${batchSize.cans_per_batch.toLocaleString()}</p>
              </div>
            </div>
            
            <div class="summary">
              <h2>Cost Summary</h2>
              <table>
                <tr>
                  <td>Total Ingredients:</td>
                  <td>$${formatNumber(costSummary?.totalIngredientCost || 0)}</td>
                </tr>
                <tr>
                  <td>Total Packaging:</td>
                  <td>$${formatNumber(costSummary?.totalPackagingCost || 0)}</td>
                </tr>
                <tr>
                  <td>Total Freight:</td>
                  <td>$${formatNumber(costSummary?.totalFreightCost || 0)}</td>
                </tr>
                <tr>
                  <td>Total Tolling:</td>
                  <td>$${formatNumber(costSummary?.totalTollingCost || 0)}</td>
                </tr>
                <tr>
                  <td><strong>Total Batch Cost:</strong></td>
                  <td><strong>$${formatNumber(costSummary?.totalBatchCost || 0)}</strong></td>
                </tr>
                <tr>
                  <td><strong>Cost Per Can:</strong></td>
                  <td><strong>$${formatNumber(costSummary?.costPerCan || 0)}</strong></td>
                </tr>
              </table>
            </div>
            
            <h2>Order Details by Ingredient</h2>
            <table>
              <thead>
                <tr>
                  <th>Part #</th>
                  <th>Ingredient</th>
                  <th>Supplier</th>
                  <th>Current Stock</th>
                  <th>Need</th>
                  <th>Order Quantity</th>
                  <th>Pails</th>
                  <th>Total Cost</th>
                </tr>
              </thead>
              <tbody>
                ${items.map(item => `
                  <tr>
                    <td>${item.part_number || 'N/A'}</td>
                    <td>${item.name}</td>
                    <td>${item.supplier.name}</td>
                    <td>${formatNumber(item.current_level)} ${item.unit}</td>
                    <td>${formatNumber(item.batch_requirement)} ${item.unit}</td>
                    <td>${formatNumber(item.totalOrdered)} ${item.unit}</td>
                    <td>${item.pailsNeeded} pails</td>
                    <td>$${formatNumber(item.totalCost)}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
            
            <div class="supplier-section">
              <h2>Order Details by Supplier</h2>
              ${Array.from(new Set(items.map(item => item.supplier.id))).map(supplierId => {
                const supplierItems = items.filter(item => item.supplier.id === supplierId);
                const supplierName = supplierItems[0].supplier.name;
                const totalPails = supplierItems.reduce((sum, item) => sum + item.pailsNeeded, 0);
                const totalCost = supplierItems.reduce((sum, item) => sum + item.totalCost, 0);
                const freightCost = freightCosts.find(fc => fc.supplier_id === supplierId)?.cost || 0;
                
                return `
                  <div class="supplier-section">
                    <h3 class="supplier-header">${supplierName}</h3>
                    <table>
                      <thead>
                        <tr>
                          <th>Part #</th>
                          <th>Ingredient</th>
                          <th>Pails</th>
                          <th>Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        ${supplierItems.map(item => `
                          <tr>
                            <td>${item.part_number || 'N/A'}</td>
                            <td>${item.name}</td>
                            <td>${item.pailsNeeded}</td>
                            <td>$${formatNumber(item.totalCost)}</td>
                          </tr>
                        `).join('')}
                        <tr>
                          <td colspan="2"><strong>Freight Cost:</strong></td>
                          <td colspan="2"><strong>$${formatNumber(freightCost)}</strong></td>
                        </tr>
                        <tr>
                          <td colspan="2"><strong>Total for ${supplierName}:</strong></td>
                          <td><strong>${totalPails} pails</strong></td>
                          <td><strong>$${formatNumber(totalCost + freightCost)}</strong></td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                `;
              }).join('')}
            </div>
            
            <div class="note">
              <p>Notes:</p>
              <ul>
                <li>All quantities include MOQ adjustments</li>
                <li>Freight costs are included in supplier totals</li>
                <li>Please verify all quantities before placing orders</li>
              </ul>
            </div>
          </body>
        </html>
      `;

      // Create a Blob containing the HTML content
      const blob = new Blob([content], { type: 'text/html' });
      const url = URL.createObjectURL(blob);

      // Open in a new window for printing
      const printWindow = window.open(url, '_blank');
      if (printWindow) {
        printWindow.onload = () => {
          printWindow.print();
          URL.revokeObjectURL(url);
        };
      }

      toast.success('PDF ready for printing');
    }
  };

  const saveBatchCostSummary = async () => {
    if (!costSummary) return;

    if (!localItems[0]?.flavor_id) {
      toast.error('Missing flavor information');
      return;
    }

    try {
      const { error } = await supabase.from('batch_cost_summary').insert([
        {
          flavor_id: localItems[0].flavor_id,
          batch_size_gallons: batchSize.size_gallons,
          total_ingredient_cost: costSummary.totalIngredientCost,
          total_packaging_cost: costSummary.totalPackagingCost,
          total_freight_cost: costSummary.totalFreightCost,
          total_tolling_cost: costSummary.totalTollingCost,
          total_batch_cost: costSummary.totalBatchCost,
          cost_per_can: costSummary.costPerCan,
          cans_per_batch: batchSize.cans_per_batch,
          created_at: new Date().toISOString()
        },
      ]);

      if (error) throw error;
      toast.success('Cost summary saved successfully');
    } catch (error) {
      console.error('Error saving cost summary:', error.message || error);
      toast.error('Failed to save cost summary');
    }
  };

  const saveOrder = async () => {
    try {
      // Create the order
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
          flavor_id: items[0]?.flavor_id,
          batch_size_gallons: batchSize.size_gallons,
          status: 'pending'
        })
        .select()
        .single();

      if (orderError) throw orderError;

      // Create order items
      const orderItems = items.map(item => ({
        order_id: order.id,
        ingredient_id: item.id,
        batch_requirement: item.batch_requirement,
        current_level: item.current_level,
        order_quantity: item.orderQuantity,
        pails_needed: item.pailsNeeded,
        total_ordered: item.totalOrdered,
        unit_price: item.totalCost / item.totalOrdered,
        total_cost: item.totalCost,
        unit: item.unit
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) throw itemsError;

      toast.success('Order saved successfully');
    } catch (error) {
      console.error('Error saving order:', error);
      toast.error('Failed to save order');
    }
  };

  // Get MOQ and unit from first item if available
  const firstItem = localItems[0];
  const moqDisplay = firstItem
    ? `(MOQ: ${formatNumber(firstItem.moq)} ${firstItem.unit})`
    : '';

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start">
        <h2 className="text-lg font-semibold text-gray-900">Order Summary</h2>
        <div className="space-y-2">
          <div className="bg-indigo-50 p-4 rounded-lg text-center mb-4">
            <h3 className="text-sm font-medium text-indigo-900 mb-1">Cost Per Can</h3>
            <div className="text-2xl font-bold text-indigo-600">
              ${costSummary ? formatNumber(costSummary.costPerCan) : '0.00'}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowPerCan(!showPerCan)}
              className="inline-flex items-center px-3 py-1.5 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Show {showPerCan ? 'Per Batch' : 'Per Can'} Costs
            </button>
            <button
              onClick={() => handleExport('csv')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
            >
              <Download className="h-4 w-4 mr-2" />
              Export CSV
            </button>
            <button
              onClick={() => handleExport('pdf')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
            >
              <Printer className="h-4 w-4 mr-2" />
              Export PDF
            </button>
            <button
              onClick={saveOrder}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              <Save className="h-4 w-4 mr-2" />
              Save Order
            </button>
          </div>
          {costSummary && (
            <div className="bg-white p-4 rounded-lg shadow-sm space-y-2">
              <h3 className="font-medium text-gray-900">
                {showPerCan ? 'Cost per Can' : 'Total Batch Cost'} Summary
              </h3>
              <div className="grid grid-cols-2 gap-8">
                <div className="space-y-3">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-blue-600">Ingredients</span>
                    <span className="font-medium">
                      ${formatNumber(showPerCan ? costSummary.totalIngredientCost / batchSize.cans_per_batch : costSummary.totalIngredientCost)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-orange-600">Packaging</span>
                    <span className="font-medium">
                      ${formatNumber(showPerCan ? costSummary.totalPackagingCost / batchSize.cans_per_batch : costSummary.totalPackagingCost)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-green-600">Freight</span>
                    <span className="font-medium">
                      ${formatNumber(showPerCan ? costSummary.totalFreightCost / batchSize.cans_per_batch : costSummary.totalFreightCost)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-purple-600">Tolling</span>
                    <span className="font-medium">
                      ${formatNumber(showPerCan ? costSummary.totalTollingCost / batchSize.cans_per_batch : costSummary.totalTollingCost)}
                    </span>
                  </div>
                  <div className="pt-2 border-t">
                    <div className="flex justify-between items-center text-sm font-bold">
                      <span className="text-gray-900">Total</span>
                      <span>
                        ${formatNumber(showPerCan ? costSummary.costPerCan : costSummary.totalBatchCost)}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Cost Breakdown</h4>
                  <div className="space-y-2">
                    <div className="h-2 bg-blue-600 rounded" style={{ width: `${(costSummary.totalIngredientCost / costSummary.totalBatchCost) * 100}%` }} />
                    <div className="h-2 bg-orange-600 rounded" style={{ width: `${(costSummary.totalPackagingCost / costSummary.totalBatchCost) * 100}%` }} />
                    <div className="h-2 bg-green-600 rounded" style={{ width: `${(costSummary.totalFreightCost / costSummary.totalBatchCost) * 100}%` }} />
                    <div className="h-2 bg-purple-600 rounded" style={{ width: `${(costSummary.totalTollingCost / costSummary.totalBatchCost) * 100}%` }} />
                  </div>
                </div>
              </div>
              <button
                onClick={saveBatchCostSummary}
                className="mt-4 w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Save Cost Summary
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 rounded-lg overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead>
            <tr className="bg-gray-50">
              <th className="w-8 px-2 py-3"></th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Ingredient
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Order Details
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Total Cost
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {localItems.map((item) => (
              <React.Fragment key={item.row_id}>
                <tr 
                  className={`hover:bg-gray-50 cursor-pointer`}
                  onClick={() => toggleRow(item.row_id)}
                >
                <td className="w-8 px-2 py-4">
                  {expandedRows.has(item.row_id) ? (
                    <ChevronDown className="w-4 h-4 text-gray-400" />
                  ) : (
                    <ChevronRight className="w-4 h-4 text-gray-400" />
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  <div className="flex flex-col">
                    <span>{item.name}</span>
                    <span className="text-xs text-gray-500">{item.part_number || 'No Part #'} • {item.supplier.name}</span>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <div className="flex flex-col">
                    <span>Need to Order: {formatNumber(item.orderQuantity)} {item.unit}</span>
                    <span className="text-xs text-gray-500 flex items-center gap-2">
                      {item.has_surplus ? (
                        <span className="text-green-600">Surplus Available</span>
                      ) : item.no_price ? (
                        <span className="text-yellow-600">No Price Set</span>
                      ) : (
                        `${item.pailsNeeded} pails (${formatNumber(item.totalOrdered)} ${item.unit} total)`
                      )}
                    </span>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <div className="flex flex-col">
                    <span>
                      {item.has_surplus ? (
                        <span className="text-green-600">No Cost (Surplus)</span>
                      ) : item.no_price ? (
                        <span className="text-yellow-600">Price Not Set</span>
                      ) : (
                        `$${formatNumber(item.totalCost)}`
                      )}
                    </span>
                    <span className="text-xs text-gray-500">
                      {!item.has_surplus && !item.no_price && (
                        `$${formatNumber(item.totalCost / item.totalOrdered)}/${item.unit}`
                      )}
                    </span>
                  </div>
                </td>
                </tr>
                {expandedRows.has(item.row_id) && (
                  <tr className="bg-gray-50/50">
                  <td></td>
                  <td colSpan={3} className="px-6 py-4">
                    <div className="grid grid-cols-3 gap-8">
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Requirements</h4>
                        <dl className="space-y-1">
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Batch Requirement:</dt>
                            <dd className="text-gray-900">{formatNumber(item.batch_requirement)} {item.unit}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Current Level:</dt>
                            <dd className="text-gray-900">{formatNumber(item.current_level)} {item.unit}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Shortage:</dt>
                            <dd className="text-gray-900">{formatNumber(item.batch_requirement - item.current_level)} {item.unit}</dd>
                          </div>
                        </dl>
                      </div>
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Order Details</h4>
                        <dl className="space-y-1">
                          <div className="flex justify-between">
                            <dt className="text-gray-500">MOQ:</dt>
                            <dd className="text-gray-900">{item.moq} {item.unit}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Pails Needed:</dt>
                            <dd className="text-gray-900">{item.pailsNeeded}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Total Ordered:</dt>
                            <dd className="text-gray-900">{formatNumber(item.totalOrdered)} {item.unit}</dd>
                          </div>
                        </dl>
                      </div>
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Cost Breakdown</h4>
                        <dl className="space-y-1">
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Unit Price:</dt>
                            <dd className="text-gray-900">${formatNumber(item.totalCost / item.totalOrdered)}/{item.unit}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-gray-500">Total Cost:</dt>
                            <dd className="text-gray-900">${formatNumber(item.totalCost)}</dd>
                          </div>
                         <div className="flex justify-between">
                           <dt className="text-gray-500">Cost per Can:</dt>
                           <dd className="text-gray-900">
                             <span className={`
                               ${item.has_surplus ? 'text-green-600' : ''}
                               ${item.no_price ? 'text-yellow-600' : ''}
                             `}>
                               {item.has_surplus ? '$0.00 (Surplus)' :
                                item.no_price ? 'Price Not Set' :
                                `$${formatNumber(item.cost_per_can)}`}
                             </span>
                           </dd>
                         </div>
                         <div className="flex justify-between">
                           <dt className="text-gray-500">% of Total Can Cost:</dt>
                           <dd className="text-gray-900">
                             {item.has_surplus || item.no_price ? (
                               '0%'
                             ) : (
                               `${formatNumber((item.cost_per_can / (costSummary?.costPerCan || 1)) * 100)}%`
                             )}
                           </dd>
                         </div>
                        </dl>
                      </div>
                    </div>
                  </td>
                  </tr>
                )}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}