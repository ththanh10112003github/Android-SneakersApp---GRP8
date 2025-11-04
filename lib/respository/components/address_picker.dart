import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/services/vietnam_address_service.dart';
import 'package:flutter/material.dart';

/// Model để lưu trữ địa chỉ đầy đủ
class FullAddress {
  final String? provinceCode;
  final String? provinceName;
  final String? districtCode;
  final String? districtName;
  final String? wardCode;
  final String? wardName;
  final String detailAddress;

  FullAddress({
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
    this.wardCode,
    this.wardName,
    this.detailAddress = '',
  });

  /// Tạo địa chỉ đầy đủ dạng string
  String get fullAddressString {
    final parts = <String>[];
    if (detailAddress.isNotEmpty) parts.add(detailAddress);
    if (wardName != null && wardName!.isNotEmpty) parts.add(wardName!);
    if (districtName != null && districtName!.isNotEmpty) parts.add(districtName!);
    if (provinceName != null && provinceName!.isNotEmpty) parts.add(provinceName!);
    return parts.join(', ');
  }

  /// Tạo Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'districtCode': districtCode,
      'districtName': districtName,
      'wardCode': wardCode,
      'wardName': wardName,
      'detailAddress': detailAddress,
      'fullAddress': fullAddressString,
    };
  }

  /// Tạo từ Map (khi load từ Firestore)
  factory FullAddress.fromMap(Map<String, dynamic> map) {
    return FullAddress(
      provinceCode: map['provinceCode'],
      provinceName: map['provinceName'],
      districtCode: map['districtCode'],
      districtName: map['districtName'],
      wardCode: map['wardCode'],
      wardName: map['wardName'],
      detailAddress: map['detailAddress'] ?? '',
    );
  }

  /// Tạo từ string địa chỉ cũ (backward compatibility)
  factory FullAddress.fromString(String address) {
    return FullAddress(detailAddress: address);
  }
}

/// Widget để chọn địa chỉ Việt Nam
class AddressPicker extends StatefulWidget {
  final FullAddress? initialAddress;
  final Function(FullAddress)? onAddressChanged;
  final bool showDetailAddress;
  final String? detailAddressHint;

  const AddressPicker({
    super.key,
    this.initialAddress,
    this.onAddressChanged,
    this.showDetailAddress = true,
    this.detailAddressHint,
  });

  @override
  State<AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  final TextEditingController _detailAddressController = TextEditingController();

  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _initializeFromAddress();
  }

  void _initializeFromAddress() {
    if (widget.initialAddress != null) {
      final addr = widget.initialAddress!;
      _detailAddressController.text = addr.detailAddress;
      
      if (addr.provinceCode != null) {
        _loadProvinceAndChildren(addr.provinceCode!, addr.districtCode, addr.wardCode);
      }
    }
  }

  Future<void> _loadProvinceAndChildren(
    String provinceCode,
    String? districtCode,
    String? wardCode,
  ) async {
    // Load province
    final province = await VietnamAddressService.getProvinceByCode(provinceCode);
    if (province != null) {
      setState(() {
        _selectedProvince = province;
      });
      
      // Load districts
      if (districtCode != null) {
        await _loadDistricts(provinceCode);
        
        // Find and select district
        final district = _districts.firstWhere(
          (d) => d.code == districtCode,
          orElse: () => _districts.first,
        );
        
        setState(() {
          _selectedDistrict = district;
        });
        
        // Load wards
        if (wardCode != null) {
          await _loadWards(districtCode);
          
          // Find and select ward
          Ward? ward;
          try {
            ward = _wards.firstWhere(
              (w) => w.code == wardCode,
            );
          } catch (e) {
            // If not found, use first ward if available
            ward = _wards.isNotEmpty ? _wards.first : null;
          }
          
          setState(() {
            _selectedWard = ward;
          });
        }
      }
      
      _notifyAddressChanged();
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });

    try {
      final provinces = await VietnamAddressService.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProvinces = false;
      });
      debugPrint('Error loading provinces: $e');
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _wards = [];
      _selectedWard = null;
    });

    try {
      final districts = await VietnamAddressService.getDistrictsByProvince(provinceCode);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDistricts = false;
      });
      debugPrint('Error loading districts: $e');
    }

    _notifyAddressChanged();
  }

  Future<void> _loadWards(String districtCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });

    try {
      final wards = await VietnamAddressService.getWardsByDistrict(districtCode);
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWards = false;
      });
      debugPrint('Error loading wards: $e');
    }

    _notifyAddressChanged();
  }

  void _notifyAddressChanged() {
    if (widget.onAddressChanged != null) {
      final address = FullAddress(
        provinceCode: _selectedProvince?.code,
        provinceName: _selectedProvince?.name,
        districtCode: _selectedDistrict?.code,
        districtName: _selectedDistrict?.name,
        wardCode: _selectedWard?.code,
        wardName: _selectedWard?.name,
        detailAddress: _detailAddressController.text,
      );
      widget.onAddressChanged!(address);
    }
  }

  @override
  void dispose() {
    _detailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tỉnh/Thành phố
        _buildDropdown(
          label: 'Tỉnh/Thành phố',
          value: _selectedProvince?.name,
          items: _provinces.map((p) => p.name).toList(),
          isLoading: _isLoadingProvinces,
          onChanged: (value) {
            if (value != null) {
              final province = _provinces.firstWhere((p) => p.name == value);
              setState(() {
                _selectedProvince = province;
                _selectedDistrict = null;
                _selectedWard = null;
              });
              _loadDistricts(province.code);
            }
          },
        ),
        const SizedBox(height: 16),

        // Huyện/Quận
        _buildDropdown(
          label: 'Huyện/Quận',
          value: _selectedDistrict?.name,
          items: _districts.map((d) => d.name).toList(),
          isLoading: _isLoadingDistricts,
          enabled: _selectedProvince != null,
          onChanged: (value) {
            if (value != null) {
              final district = _districts.firstWhere((d) => d.name == value);
              setState(() {
                _selectedDistrict = district;
                _selectedWard = null;
              });
              _loadWards(district.code);
            }
          },
        ),
        const SizedBox(height: 16),

        // Xã/Phường
        _buildDropdown(
          label: 'Xã/Phường',
          value: _selectedWard?.name,
          items: _wards.map((w) => w.name).toList(),
          isLoading: _isLoadingWards,
          enabled: _selectedDistrict != null,
          onChanged: (value) {
            if (value != null) {
              final ward = _wards.firstWhere((w) => w.name == value);
              setState(() {
                _selectedWard = ward;
              });
              _notifyAddressChanged();
            }
          },
        ),
        const SizedBox(height: 16),

        // Địa chỉ chi tiết
        if (widget.showDetailAddress)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Địa chỉ chi tiết',
                style: TextStyling.formtextstyle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailAddressController,
                decoration: InputDecoration(
                  hintText: widget.detailAddressHint ?? 'Số nhà, tên đường...',
                  hintStyle: TextStyling.hinttext,
                  filled: true,
                  fillColor: const Color(0xffF7F7F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => _notifyAddressChanged(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyling.formtextstyle,
        ),
        const SizedBox(height: 8),
        isLoading
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xffF7F7F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xffF7F7F9)
                      : const Color(0xffF7F7F9).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: items.isEmpty ? null : value,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColor.backgroundColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: Text(
                    'Chọn $label',
                    style: TextStyling.hinttext,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xff2B2B2B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: enabled && items.isNotEmpty ? onChanged : null,
                  dropdownColor: Colors.white,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xff6A6A6A),
                  ),
                  isExpanded: true,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xff2B2B2B),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return items.map<Widget>((String item) {
                      return Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xff2B2B2B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                ),
              ),
      ],
    );
  }
}
